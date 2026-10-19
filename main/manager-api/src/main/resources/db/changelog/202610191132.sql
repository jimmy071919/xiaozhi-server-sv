-- Clarify cloud/local inference labels and use the Taiwan spelling for silicon.
-- Display names only; provider types, model IDs, and runtime settings are unchanged.
UPDATE `ai_model_provider`
SET `name` = 'Edge TTS（雲端）'
WHERE `id` = 'SYSTEM_TTS_edge';

UPDATE `ai_model_provider`
SET `name` = '矽基流動 TTS'
WHERE `id` = 'SYSTEM_TTS_siliconflow';

UPDATE `ai_model_config`
SET `model_name` = 'Edge TTS 雲端語音合成'
WHERE `id` = 'TTS_EdgeTTS';

UPDATE `ai_model_config`
SET `model_name` = '矽基流動語音合成'
WHERE `id` = 'TTS_CosyVoiceSiliconflow';
