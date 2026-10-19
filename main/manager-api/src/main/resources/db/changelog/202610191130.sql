CREATE TABLE IF NOT EXISTS `ai_codex_oauth_credential` (
  `model_id` varchar(32) NOT NULL COMMENT 'ai_model_config.id; credentials never enter config_json',
  `encrypted_payload` mediumtext NOT NULL COMMENT 'AES-256-GCM ciphertext containing OAuth/device credentials',
  `nonce` varchar(32) NOT NULL COMMENT 'base64 96-bit GCM nonce',
  `status` varchar(16) NOT NULL,
  `expires_at` datetime NULL,
  `create_date` datetime NOT NULL,
  `update_date` datetime NOT NULL,
  PRIMARY KEY (`model_id`),
  CONSTRAINT `fk_codex_oauth_model` FOREIGN KEY (`model_id`) REFERENCES `ai_model_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Encrypted native OpenAI Codex OAuth credentials';

-- Remove only the provider definition introduced by 202610190810; never mutate existing models.
DELETE FROM `ai_model_provider`
WHERE `id` = 'SYSTEM_LLM_codex_subscription';

-- Native Codex OAuth is a distinct provider, independent of existing model configuration.
INSERT INTO `ai_model_provider`
(`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`)
VALUES
(
  'SYSTEM_LLM_codex_oauth',
  'LLM',
  'codex_oauth',
  'OpenAI Codex 訂閱（原生 OAuth）',
  JSON_ARRAY(
    JSON_OBJECT('key', 'model_name', 'type', 'string', 'label', 'Codex 模型名稱')
  ),
  2,
  NULL,
  NOW(),
  NULL,
  NOW()
)
ON DUPLICATE KEY UPDATE
`provider_code` = VALUES(`provider_code`),
`name` = VALUES(`name`),
`fields` = VALUES(`fields`),
`sort` = VALUES(`sort`),
`update_date` = NOW();

-- Add native Codex OAuth as a separate opt-in model. Do not switch any existing agent.
INSERT INTO `ai_model_config`
(`id`, `model_type`, `model_code`, `model_name`, `is_default`, `is_enabled`, `config_json`,
 `doc_link`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`)
VALUES
(
  '6390797c16aa47f583953d2614a2f958',
  'LLM',
  'LLM_OpenAICodexOAuth',
  'OpenAI Codex 訂閱（原生 OAuth）',
  0,
  1,
  JSON_OBJECT('type', 'codex_oauth', 'model_name', 'gpt-5-codex'),
  'https://github.com/openai/codex/tree/main/codex-rs/login',
  '小智原生 OpenAI Codex device OAuth；憑證以 AES-256-GCM 加密，不寫入模型設定。',
  2,
  NULL,
  NOW(),
  NULL,
  NOW()
)
ON DUPLICATE KEY UPDATE
`model_code` = VALUES(`model_code`),
`model_name` = VALUES(`model_name`),
`is_enabled` = VALUES(`is_enabled`),
`config_json` = VALUES(`config_json`),
`doc_link` = VALUES(`doc_link`),
`remark` = VALUES(`remark`),
`sort` = VALUES(`sort`),
`update_date` = NOW();
