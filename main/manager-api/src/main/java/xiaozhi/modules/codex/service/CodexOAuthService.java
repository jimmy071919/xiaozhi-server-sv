package xiaozhi.modules.codex.service;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import cn.hutool.json.JSONObject;
import lombok.RequiredArgsConstructor;
import xiaozhi.modules.codex.dao.CodexOAuthCredentialDao;
import xiaozhi.modules.codex.entity.CodexOAuthCredentialEntity;
import xiaozhi.modules.model.entity.ModelConfigEntity;
import xiaozhi.modules.model.service.ModelConfigService;

@Service
@RequiredArgsConstructor
public class CodexOAuthService {
    public static final String ISSUER = "https://auth.openai.com";
    public static final String CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann";
    public static final String VERIFICATION_URI = ISSUER + "/codex/device";
    private static final String USER_CODE_URL = ISSUER + "/api/accounts/deviceauth/usercode";
    private static final String DEVICE_TOKEN_URL = ISSUER + "/api/accounts/deviceauth/token";
    private static final String OAUTH_TOKEN_URL = ISSUER + "/oauth/token";
    private static final long LOGIN_TTL_SECONDS = 15 * 60;
    private static final long REFRESH_SKEW_SECONDS = 5 * 60;

    private final CodexOAuthCredentialDao credentialDao;
    private final ModelConfigService modelConfigService;
    private final CodexCredentialCipher cipher;
    private final ObjectMapper objectMapper;
    private final RestClient.Builder restClientBuilder;

    @Transactional
    public LoginStart start(String modelId) {
        requireCodexModel(modelId);
        JsonNode response = restClientBuilder.build().post().uri(USER_CODE_URL)
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of("client_id", CLIENT_ID))
                .retrieve().body(JsonNode.class);
        if (response == null || text(response, "device_auth_id") == null) {
            throw new IllegalStateException("OpenAI device authorization returned an invalid response");
        }
        String userCode = firstText(response, "user_code", "usercode");
        long interval = parseLong(response.get("interval"), 5);
        CredentialPayload payload = new CredentialPayload();
        payload.deviceAuthId = text(response, "device_auth_id");
        payload.userCode = userCode;
        payload.pollInterval = interval;
        save(modelId, payload, "pending", LocalDateTime.now(ZoneOffset.UTC).plusSeconds(LOGIN_TTL_SECONDS));
        return new LoginStart(VERIFICATION_URI, userCode, interval, LOGIN_TTL_SECONDS);
    }

    @Transactional
    public OAuthStatus poll(String modelId) {
        CodexOAuthCredentialEntity entity = requireCredential(modelId);
        if ("connected".equals(entity.getStatus())) {
            CredentialPayload payload = decrypt(entity);
            return status(entity, payload);
        }
        if (entity.getExpiresAt() != null && entity.getExpiresAt().isBefore(LocalDateTime.now(ZoneOffset.UTC))) {
            entity.setStatus("expired");
            entity.setUpdateDate(LocalDateTime.now(ZoneOffset.UTC));
            credentialDao.updateById(entity);
            return new OAuthStatus("expired", false, null, null);
        }
        CredentialPayload pending = decrypt(entity);
        try {
            JsonNode code = restClientBuilder.build().post().uri(DEVICE_TOKEN_URL)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("device_auth_id", pending.deviceAuthId, "user_code", pending.userCode))
                    .retrieve().body(JsonNode.class);
            if (code == null) {
                throw new IllegalStateException("OpenAI device token response was empty");
            }
            CredentialPayload connected = exchangeCode(code);
            LocalDateTime expiresAt = toUtc(connected.expiresAtEpochSeconds);
            save(modelId, connected, "connected", expiresAt);
            return new OAuthStatus("connected", true, connected.accountId, expiresAt);
        } catch (HttpClientErrorException e) {
            if (e.getStatusCode().value() == 403 || e.getStatusCode().value() == 404) {
                return new OAuthStatus("pending", false, null, entity.getExpiresAt());
            }
            throw new IllegalStateException("OpenAI device authorization was rejected (HTTP "
                    + e.getStatusCode().value() + ")");
        }
    }

    public OAuthStatus status(String modelId) {
        CodexOAuthCredentialEntity entity = credentialDao.selectById(modelId);
        if (entity == null) {
            return new OAuthStatus("disconnected", false, null, null);
        }
        CredentialPayload payload = decrypt(entity);
        return status(entity, payload);
    }

    @Transactional
    public void logout(String modelId) {
        credentialDao.deleteById(modelId);
    }

    @Transactional
    public synchronized BrokerToken brokerToken(String modelId) {
        CodexOAuthCredentialEntity entity = requireCredential(modelId);
        if (!"connected".equals(entity.getStatus())) {
            throw new IllegalStateException("Codex OAuth account is not connected");
        }
        CredentialPayload payload = decrypt(entity);
        long now = Instant.now().getEpochSecond();
        if (payload.expiresAtEpochSeconds == null || payload.expiresAtEpochSeconds <= now + REFRESH_SKEW_SECONDS) {
            payload = refresh(payload);
            save(modelId, payload, "connected", toUtc(payload.expiresAtEpochSeconds));
        }
        return new BrokerToken(payload.accessToken, payload.accountId,
                toUtc(payload.expiresAtEpochSeconds));
    }

    private CredentialPayload exchangeCode(JsonNode code) {
        LinkedMultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "authorization_code");
        form.add("client_id", CLIENT_ID);
        form.add("code", requiredText(code, "authorization_code"));
        form.add("redirect_uri", ISSUER + "/deviceauth/callback");
        form.add("code_verifier", requiredText(code, "code_verifier"));
        JsonNode response = restClientBuilder.build().post().uri(OAUTH_TOKEN_URL)
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(form).retrieve().body(JsonNode.class);
        return tokenPayload(response, null);
    }

    private CredentialPayload refresh(CredentialPayload existing) {
        if (existing.refreshToken == null || existing.refreshToken.isBlank()) {
            throw new IllegalStateException("Codex OAuth refresh token is missing; reconnect the account");
        }
        Map<String, String> request = new LinkedHashMap<>();
        request.put("client_id", CLIENT_ID);
        request.put("grant_type", "refresh_token");
        request.put("refresh_token", existing.refreshToken);
        request.put("refresh_reason", "proactive_expiry");
        JsonNode response = restClientBuilder.build().post().uri(OAUTH_TOKEN_URL)
                .contentType(MediaType.APPLICATION_JSON)
                .body(request).retrieve().body(JsonNode.class);
        CredentialPayload refreshed = tokenPayload(response, existing.refreshToken);
        if (refreshed.accountId == null) refreshed.accountId = existing.accountId;
        if (refreshed.idToken == null) refreshed.idToken = existing.idToken;
        return refreshed;
    }

    private CredentialPayload tokenPayload(JsonNode response, String previousRefreshToken) {
        if (response == null) {
            throw new IllegalStateException("OpenAI OAuth token response was empty");
        }
        CredentialPayload payload = new CredentialPayload();
        payload.accessToken = requiredText(response, "access_token");
        payload.refreshToken = firstText(response, "refresh_token");
        if (payload.refreshToken == null) {
            payload.refreshToken = previousRefreshToken;
        }
        payload.idToken = firstText(response, "id_token");
        payload.accountId = accountId(payload.idToken != null ? payload.idToken : payload.accessToken);
        long expiresIn = parseLong(response.get("expires_in"), 3600);
        Long jwtExpiry = jwtLong(payload.accessToken, "exp");
        payload.expiresAtEpochSeconds = jwtExpiry != null ? jwtExpiry : Instant.now().getEpochSecond() + expiresIn;
        return payload;
    }

    private void requireCodexModel(String modelId) {
        ModelConfigEntity model = modelConfigService.selectById(modelId);
        JSONObject config = model == null ? null : model.getConfigJson();
        if (model == null || !"LLM".equalsIgnoreCase(model.getModelType()) || config == null
                || !"codex_oauth".equals(config.getStr("type"))) {
            throw new IllegalArgumentException("The requested model is not a codex_oauth LLM");
        }
    }

    private CodexOAuthCredentialEntity requireCredential(String modelId) {
        CodexOAuthCredentialEntity entity = credentialDao.selectById(modelId);
        if (entity == null) {
            throw new IllegalStateException("Codex OAuth account is not connected");
        }
        return entity;
    }

    private OAuthStatus status(CodexOAuthCredentialEntity entity, CredentialPayload payload) {
        boolean connected = "connected".equals(entity.getStatus());
        return new OAuthStatus(entity.getStatus(), connected, connected ? payload.accountId : null,
                entity.getExpiresAt());
    }

    private void save(String modelId, CredentialPayload payload, String status, LocalDateTime expiresAt) {
        try {
            CodexCredentialCipher.Encrypted encrypted = cipher.encrypt(objectMapper.writeValueAsString(payload), modelId);
            CodexOAuthCredentialEntity entity = new CodexOAuthCredentialEntity();
            entity.setModelId(modelId);
            entity.setEncryptedPayload(encrypted.ciphertext());
            entity.setNonce(encrypted.nonce());
            entity.setStatus(status);
            entity.setExpiresAt(expiresAt);
            entity.setUpdateDate(LocalDateTime.now(ZoneOffset.UTC));
            if (credentialDao.selectById(modelId) == null) {
                entity.setCreateDate(entity.getUpdateDate());
                credentialDao.insert(entity);
            } else {
                credentialDao.updateById(entity);
            }
        } catch (Exception e) {
            if (e instanceof IllegalStateException state) {
                throw state;
            }
            throw new IllegalStateException("Unable to store Codex OAuth credential", e);
        }
    }

    private CredentialPayload decrypt(CodexOAuthCredentialEntity entity) {
        try {
            return objectMapper.readValue(
                    cipher.decrypt(entity.getEncryptedPayload(), entity.getNonce(), entity.getModelId()),
                    CredentialPayload.class);
        } catch (Exception e) {
            if (e instanceof IllegalStateException state) {
                throw state;
            }
            throw new IllegalStateException("Unable to read Codex OAuth credential", e);
        }
    }

    private String accountId(String jwt) {
        if (jwt == null) return null;
        try {
            JsonNode payload = jwtPayload(jwt);
            JsonNode auth = payload.get("https://api.openai.com/auth");
            if (auth != null && auth.hasNonNull("chatgpt_account_id")) {
                return auth.get("chatgpt_account_id").asText();
            }
            return payload.hasNonNull("chatgpt_account_id") ? payload.get("chatgpt_account_id").asText() : null;
        } catch (Exception ignored) {
            return null;
        }
    }

    private Long jwtLong(String jwt, String claim) {
        try {
            JsonNode value = jwtPayload(jwt).get(claim);
            return value == null ? null : value.asLong();
        } catch (Exception ignored) {
            return null;
        }
    }

    private JsonNode jwtPayload(String jwt) throws Exception {
        String[] parts = jwt.split("\\.");
        if (parts.length < 2) throw new IllegalArgumentException("Invalid JWT");
        return objectMapper.readTree(Base64.getUrlDecoder().decode(parts[1]));
    }

    private static String requiredText(JsonNode node, String field) {
        String value = text(node, field);
        if (value == null || value.isBlank()) throw new IllegalStateException("OpenAI response is missing " + field);
        return value;
    }

    private static String firstText(JsonNode node, String... fields) {
        for (String field : fields) {
            String value = text(node, field);
            if (value != null) return value;
        }
        return null;
    }

    private static String text(JsonNode node, String field) {
        JsonNode value = node == null ? null : node.get(field);
        return value == null || value.isNull() ? null : value.asText();
    }

    private static long parseLong(JsonNode node, long fallback) {
        if (node == null || node.isNull()) return fallback;
        try { return Long.parseLong(node.asText().trim()); } catch (NumberFormatException e) { return fallback; }
    }

    private static LocalDateTime toUtc(Long epochSeconds) {
        return epochSeconds == null ? null : LocalDateTime.ofInstant(Instant.ofEpochSecond(epochSeconds), ZoneOffset.UTC);
    }

    public static class CredentialPayload {
        public String deviceAuthId;
        public String userCode;
        public Long pollInterval;
        public String accessToken;
        public String refreshToken;
        public String idToken;
        public String accountId;
        public Long expiresAtEpochSeconds;
    }

    public record LoginStart(String verificationUri, String userCode, long interval, long expiresIn) {}
    public record OAuthStatus(String status, boolean connected, String accountId, LocalDateTime expiresAt) {}
    public record BrokerToken(String accessToken, String accountId, LocalDateTime expiresAt) {}
}
