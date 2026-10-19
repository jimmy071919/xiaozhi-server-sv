-- Use the supported fast Codex model for the existing opt-in Codex model.
-- Keep the agent/model assignment and all unrelated settings unchanged.
UPDATE `ai_model_provider`
SET `fields` = JSON_ARRAY(
  JSON_OBJECT('key', 'model_name', 'type', 'string', 'label', 'Codex 模型名稱'),
  JSON_OBJECT('key', 'service_tier', 'type', 'string', 'label', 'Codex 速度模式',
              'placeholder', 'priority（Fast）')
),
`update_date` = NOW()
WHERE `id` = 'SYSTEM_LLM_codex_oauth';

UPDATE `ai_model_config`
SET `model_name` = 'OpenAI Codex 訂閱（GPT-6 Sol 快速）',
    `config_json` = JSON_SET(
      `config_json`,
      '$.model_name', 'gpt-6-sol',
      '$.service_tier', 'priority'
    ),
    `update_date` = NOW()
WHERE `id` = '6390797c16aa47f583953d2614a2f958'
  AND JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.type')) = 'codex_oauth';
