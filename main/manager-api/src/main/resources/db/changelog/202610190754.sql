-- Taiwan-first defaults. Existing ai_agent rows (including jimmy) are intentionally untouched.

INSERT INTO `ai_tts_voice`
(`id`, `tts_model_id`, `name`, `tts_voice`, `languages`, `voice_demo`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`)
VALUES
('TTS_EdgeTTS0012', 'TTS_EdgeTTS', 'EdgeTTS 女聲－曉臻', 'zh-TW-HsiaoChenNeural', '台灣華語', NULL, '台灣繁體中文', 1, NULL, NOW(), NULL, NOW()),
('TTS_EdgeTTS0013', 'TTS_EdgeTTS', 'EdgeTTS 女聲－曉雨', 'zh-TW-HsiaoYuNeural', '台灣華語', NULL, '台灣繁體中文', 2, NULL, NOW(), NULL, NOW()),
('TTS_EdgeTTS0014', 'TTS_EdgeTTS', 'EdgeTTS 男聲－雲哲', 'zh-TW-YunJheNeural', '台灣華語', NULL, '台灣繁體中文', 3, NULL, NOW(), NULL, NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`),
`tts_voice` = VALUES(`tts_voice`),
`languages` = VALUES(`languages`),
`remark` = VALUES(`remark`),
`sort` = VALUES(`sort`),
`update_date` = NOW();

UPDATE `ai_model_config`
SET `config_json` = JSON_SET(`config_json`, '$.voice', 'zh-TW-HsiaoChenNeural'),
    `update_date` = NOW()
WHERE `id` = 'TTS_EdgeTTS';

-- Keep Jimmy's prompt, models and behaviour; only switch the requested TTS voice.
UPDATE `ai_agent`
SET `tts_voice_id` = 'TTS_EdgeTTS0012',
    `tts_language` = '台灣華語',
    `updated_at` = NOW()
WHERE `agent_name` = 'jimmy'
  AND `tts_model_id` = 'TTS_EdgeTTS';

-- Remove the old bundled character prompts and leave one neutral Taiwan default.
DELETE FROM `ai_agent_template`;

INSERT INTO `ai_agent_template`
(`id`, `agent_code`, `agent_name`, `asr_model_id`, `vad_model_id`, `llm_model_id`, `vllm_model_id`, `tts_model_id`, `tts_voice_id`, `tts_language`, `tts_volume`, `tts_rate`, `tts_pitch`, `mem_model_id`, `intent_model_id`, `system_prompt`, `summary_memory`, `chat_history_conf`, `lang_code`, `language`, `sort`, `creator`, `created_at`, `updater`, `updated_at`)
VALUES
('tw_default_assistant_20261019', '小智', '台灣語音助理', 'ASR_FunASR', 'VAD_SileroVAD', 'LLM_ChatGLMLLM', 'VLLM_ChatGLMVLLM', 'TTS_EdgeTTS', 'TTS_EdgeTTS0012', '台灣華語', NULL, NULL, NULL, 'Memory_nomem', 'Intent_function_call', '請使用臺灣繁體中文與臺灣慣用語自然回應。回答要簡潔、口語、友善，不使用簡體字，不預設或宣稱任何政治立場、國籍或族群身分。', '', 0, 'zh-TW', '繁體中文', 1, NULL, NOW(), NULL, NOW());
