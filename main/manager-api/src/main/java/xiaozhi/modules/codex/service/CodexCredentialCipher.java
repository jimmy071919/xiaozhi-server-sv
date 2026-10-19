package xiaozhi.modules.codex.service;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class CodexCredentialCipher {
    private static final int NONCE_BYTES = 12;
    private static final int TAG_BITS = 128;
    private final byte[] key;
    private final SecureRandom random = new SecureRandom();

    public CodexCredentialCipher(@Value("${codex.oauth.encryption-key:}") String configuredKey) {
        this.key = decodeKey(configuredKey);
    }

    static byte[] decodeKey(String configuredKey) {
        if (configuredKey == null || configuredKey.isBlank()) {
            return null;
        }
        byte[] decoded;
        try {
            decoded = Base64.getDecoder().decode(configuredKey.trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("CODEX_OAUTH_ENCRYPTION_KEY must be base64 encoded", e);
        }
        if (decoded.length != 32) {
            throw new IllegalStateException("CODEX_OAUTH_ENCRYPTION_KEY must decode to exactly 32 bytes");
        }
        return decoded;
    }

    public Encrypted encrypt(String plaintext, String associatedData) {
        requireKey();
        byte[] nonce = new byte[NONCE_BYTES];
        random.nextBytes(nonce);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "AES"), new GCMParameterSpec(TAG_BITS, nonce));
            cipher.updateAAD(associatedData.getBytes(StandardCharsets.UTF_8));
            byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            return new Encrypted(Base64.getEncoder().encodeToString(ciphertext),
                    Base64.getEncoder().encodeToString(nonce));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("Unable to encrypt Codex OAuth credential", e);
        }
    }

    public String decrypt(String ciphertext, String nonce, String associatedData) {
        requireKey();
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "AES"),
                    new GCMParameterSpec(TAG_BITS, Base64.getDecoder().decode(nonce)));
            cipher.updateAAD(associatedData.getBytes(StandardCharsets.UTF_8));
            return new String(cipher.doFinal(Base64.getDecoder().decode(ciphertext)), StandardCharsets.UTF_8);
        } catch (GeneralSecurityException | IllegalArgumentException e) {
            throw new IllegalStateException("Unable to decrypt Codex OAuth credential", e);
        }
    }

    private void requireKey() {
        if (key == null) {
            throw new IllegalStateException("CODEX_OAUTH_ENCRYPTION_KEY is required for Codex OAuth operations");
        }
    }

    public record Encrypted(String ciphertext, String nonce) {
    }
}
