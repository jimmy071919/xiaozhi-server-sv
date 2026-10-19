package xiaozhi.modules.codex.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import org.junit.jupiter.api.Test;

class CodexCredentialCipherTest {
    private static String key() {
        return Base64.getEncoder().encodeToString("0123456789abcdef0123456789abcdef".getBytes(StandardCharsets.UTF_8));
    }

    @Test
    void roundTripsWithModelIdAsAssociatedData() {
        CodexCredentialCipher cipher = new CodexCredentialCipher(key());
        CodexCredentialCipher.Encrypted encrypted = cipher.encrypt("secret tokens", "model-a");
        assertNotEquals("secret tokens", encrypted.ciphertext());
        assertEquals("secret tokens", cipher.decrypt(encrypted.ciphertext(), encrypted.nonce(), "model-a"));
        assertThrows(IllegalStateException.class,
                () -> cipher.decrypt(encrypted.ciphertext(), encrypted.nonce(), "model-b"));
    }

    @Test
    void rejectsMissingAndNon256BitKeysWhenUsed() {
        CodexCredentialCipher missing = new CodexCredentialCipher("");
        assertThrows(IllegalStateException.class, () -> missing.encrypt("x", "model"));
        assertThrows(IllegalStateException.class,
                () -> new CodexCredentialCipher(Base64.getEncoder().encodeToString(new byte[16])));
    }
}
