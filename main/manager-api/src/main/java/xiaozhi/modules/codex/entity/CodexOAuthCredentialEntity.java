package xiaozhi.modules.codex.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import lombok.Data;

@Data
@TableName("ai_codex_oauth_credential")
public class CodexOAuthCredentialEntity {
    @TableId
    private String modelId;
    private String encryptedPayload;
    private String nonce;
    private String status;
    private LocalDateTime expiresAt;
    private LocalDateTime createDate;
    private LocalDateTime updateDate;
}
