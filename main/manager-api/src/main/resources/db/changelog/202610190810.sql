-- Expose the existing Hermes-backed Codex subscription path as a clear LLM provider.
-- OAuth credentials remain in Hermes; Xiaozhi only calls its authenticated local API.

INSERT INTO `ai_model_provider`
(`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`)
VALUES
(
  'SYSTEM_LLM_codex_subscription',
  'LLM',
  'openai',
  'OpenAI Codex 訂閱（Hermes OAuth）',
  JSON_ARRAY(
    JSON_OBJECT('key', 'base_url', 'type', 'string', 'label', 'Hermes API 網址'),
    JSON_OBJECT('key', 'model_name', 'type', 'string', 'label', '模型名稱'),
    JSON_OBJECT('key', 'api_key', 'type', 'string', 'label', 'Hermes API 金鑰'),
    JSON_OBJECT('key', 'temperature', 'type', 'number', 'label', '溫度'),
    JSON_OBJECT('key', 'max_tokens', 'type', 'number', 'label', '最大 Token 數'),
    JSON_OBJECT('key', 'top_p', 'type', 'number', 'label', 'Top P'),
    JSON_OBJECT('key', 'top_k', 'type', 'number', 'label', 'Top K'),
    JSON_OBJECT('key', 'frequency_penalty', 'type', 'number', 'label', '重複抑制')
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

-- Keep the stable ID so every assigned agent remains linked to the same model.
UPDATE `ai_model_config`
SET `model_code` = 'LLM_OpenAICodexSubscription',
    `model_name` = 'OpenAI Codex 訂閱（Hermes）',
    `doc_link` = 'https://hermes-agent.nousresearch.com/docs/integrations/providers/openai-codex/',
    `remark` = '透過 Hermes OAuth 使用 OpenAI 訂閱帳號；Xiaozhi 不保存 OpenAI OAuth 憑證。',
    `update_date` = NOW()
WHERE `id` = '087426ff0e95e53984a08bcdff53576e';
