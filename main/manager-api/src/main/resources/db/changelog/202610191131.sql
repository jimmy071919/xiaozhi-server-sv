-- Taiwan Traditional Chinese display names only; provider codes, model IDs,
-- config_json, and agent assignments are intentionally unchanged.
UPDATE `ai_model_provider`
SET `name` = CASE `id`
  WHEN 'SYSTEM_ASR_FunASR' THEN 'FunASR 本機語音辨識'
  WHEN 'SYSTEM_ASR_SherpaASR' THEN 'Sherpa 本機語音辨識'
  WHEN 'SYSTEM_ASR_DoubaoASR' THEN '火山引擎語音辨識'
  WHEN 'SYSTEM_ASR_DoubaoStreamASR' THEN '火山引擎串流語音辨識'
  WHEN 'SYSTEM_ASR_FunASRServer' THEN 'FunASR 伺服器語音辨識'
  WHEN 'SYSTEM_ASR_TencentASR' THEN '騰訊語音辨識'
  WHEN 'SYSTEM_ASR_AliyunASR' THEN '阿里雲語音辨識'
  WHEN 'SYSTEM_ASR_AliyunStreamASR' THEN '阿里雲串流語音辨識'
  WHEN 'SYSTEM_ASR_BaiduASR' THEN '百度語音辨識'
  WHEN 'SYSTEM_ASR_OpenaiASR' THEN 'OpenAI 語音辨識'
  WHEN 'SYSTEM_ASR_VoskASR' THEN 'Vosk 離線語音辨識'
  WHEN 'SYSTEM_ASR_Qwen3Flash' THEN 'Qwen3-ASR-Flash 語音辨識'
  WHEN 'SYSTEM_ASR_AliyunBLStream' THEN '阿里百鍊 Paraformer 即時語音辨識'
  WHEN 'SYSTEM_ASR_XunfeiStream' THEN '科大訊飛串流語音辨識'
  WHEN 'SYSTEM_Intent_nointent' THEN '無意圖辨識'
  WHEN 'SYSTEM_Intent_intent_llm' THEN '外掛大型語言模型意圖辨識'
  WHEN 'SYSTEM_Intent_function_call' THEN '大型語言模型函式呼叫'
  WHEN 'SYSTEM_LLM_openai' THEN 'OpenAI 介面'
  WHEN 'SYSTEM_LLM_AliBL' THEN '阿里百鍊介面'
  WHEN 'SYSTEM_LLM_ollama' THEN 'Ollama 介面'
  WHEN 'SYSTEM_LLM_dify' THEN 'Dify 介面'
  WHEN 'SYSTEM_LLM_gemini' THEN 'Gemini 介面'
  WHEN 'SYSTEM_LLM_coze' THEN 'Coze 介面'
  WHEN 'SYSTEM_LLM_fastgpt' THEN 'FastGPT 介面'
  WHEN 'SYSTEM_LLM_xinference' THEN 'Xinference 介面'
  WHEN 'SYSTEM_Memory_mem0ai' THEN 'Mem0AI 記憶'
  WHEN 'SYSTEM_Memory_nomem' THEN '不使用記憶'
  WHEN 'SYSTEM_Memory_mem_local_short' THEN '本機短期記憶（摘要）'
  WHEN 'SYSTEM_Memory_powermem' THEN 'PowerMem 記憶'
  WHEN 'SYSTEM_Memory_mem_report_only' THEN '僅回報聊天紀錄（不產生摘要）'
  WHEN 'SYSTEM_PLUGIN_HA_STATE' THEN 'Home Assistant 裝置控制'
  WHEN 'SYSTEM_PLUGIN_HA_PLAY_MUSIC' THEN 'Home Assistant 音樂播放'
  WHEN 'SYSTEM_PLUGIN_WEB_SEARCH' THEN '網路搜尋'
  WHEN 'SYSTEM_PLUGIN_CALL_DEVICE' THEN '裝置呼叫'
  WHEN 'SYSTEM_TTS_edge' THEN 'Edge TTS'
  WHEN 'SYSTEM_TTS_doubao' THEN '火山引擎 TTS'
  WHEN 'SYSTEM_TTS_siliconflow' THEN '硅基流動 TTS'
  WHEN 'SYSTEM_TTS_cozecn' THEN 'CozeCN TTS'
  WHEN 'SYSTEM_TTS_TencentTTS' THEN '騰訊語音合成'
  WHEN 'SYSTEM_TTS_fishspeech' THEN 'FishSpeech TTS'
  WHEN 'SYSTEM_TTS_gpt_sovits_v2' THEN 'GPT-SoVITS V2'
  WHEN 'SYSTEM_TTS_gpt_sovits_v3' THEN 'GPT-SoVITS V3'
  WHEN 'SYSTEM_TTS_aliyun' THEN '阿里雲 TTS'
  WHEN 'SYSTEM_TTS_openai' THEN 'OpenAI TTS'
  WHEN 'SYSTEM_TTS_custom' THEN '自訂 TTS'
  WHEN 'SYSTEM_TTS_HSDSTTS' THEN '火山引擎雙串流語音合成'
  WHEN 'SYSTEM_TTS_AliyunStreamTTS' THEN '阿里雲串流語音合成'
  WHEN 'SYSTEM_TTS_IndexStreamTTS' THEN 'Index-TTS-vLLM 串流語音合成'
  WHEN 'SYSTEM_TTS_PaddleSpeechTTS' THEN 'PaddleSpeech TTS'
  WHEN 'SYSTEM_TTS_MinimaxStreamTTS' THEN 'MiniMax 串流語音合成'
  WHEN 'SYSTEM_TTS_AliBLStreamTTS' THEN '阿里百鍊串流語音合成'
  WHEN 'SYSTEM_TTS_XunFeiStreamTTS' THEN '科大訊飛串流語音合成'
  WHEN 'SYSTEM_VAD_SileroVAD' THEN 'Silero VAD 語音活動偵測'
  WHEN 'SYSTEM_VLLM_openai' THEN 'OpenAI 介面'
  ELSE `name`
END
WHERE `id` IN (
  'SYSTEM_ASR_FunASR','SYSTEM_ASR_SherpaASR','SYSTEM_ASR_DoubaoASR','SYSTEM_ASR_DoubaoStreamASR',
  'SYSTEM_ASR_FunASRServer','SYSTEM_ASR_TencentASR','SYSTEM_ASR_AliyunASR','SYSTEM_ASR_AliyunStreamASR',
  'SYSTEM_ASR_BaiduASR','SYSTEM_ASR_OpenaiASR','SYSTEM_ASR_VoskASR','SYSTEM_ASR_Qwen3Flash',
  'SYSTEM_ASR_AliyunBLStream','SYSTEM_ASR_XunfeiStream','SYSTEM_Intent_nointent','SYSTEM_Intent_intent_llm',
  'SYSTEM_Intent_function_call','SYSTEM_LLM_openai','SYSTEM_LLM_AliBL','SYSTEM_LLM_ollama','SYSTEM_LLM_dify',
  'SYSTEM_LLM_gemini','SYSTEM_LLM_coze','SYSTEM_LLM_fastgpt','SYSTEM_LLM_xinference','SYSTEM_Memory_mem0ai',
  'SYSTEM_Memory_nomem','SYSTEM_Memory_mem_local_short','SYSTEM_Memory_powermem','SYSTEM_Memory_mem_report_only',
  'SYSTEM_PLUGIN_HA_STATE','SYSTEM_PLUGIN_HA_PLAY_MUSIC','SYSTEM_PLUGIN_WEB_SEARCH','SYSTEM_PLUGIN_CALL_DEVICE',
  'SYSTEM_TTS_edge','SYSTEM_TTS_doubao','SYSTEM_TTS_siliconflow','SYSTEM_TTS_cozecn','SYSTEM_TTS_TencentTTS',
  'SYSTEM_TTS_fishspeech','SYSTEM_TTS_gpt_sovits_v2','SYSTEM_TTS_gpt_sovits_v3','SYSTEM_TTS_aliyun',
  'SYSTEM_TTS_openai','SYSTEM_TTS_custom','SYSTEM_TTS_HSDSTTS','SYSTEM_TTS_AliyunStreamTTS',
  'SYSTEM_TTS_IndexStreamTTS','SYSTEM_TTS_PaddleSpeechTTS','SYSTEM_TTS_MinimaxStreamTTS',
  'SYSTEM_TTS_AliBLStreamTTS','SYSTEM_TTS_XunFeiStreamTTS','SYSTEM_VAD_SileroVAD','SYSTEM_VLLM_openai'
);

-- Localize built-in model display names without changing executable configuration.
UPDATE `ai_model_config`
SET `model_name` = CASE `id`
  WHEN 'ASR_FunASR' THEN 'FunASR 語音辨識（本機）'
  WHEN 'ASR_FunASRServer' THEN 'FunASR 伺服器語音辨識'
  WHEN 'ASR_SherpaASR' THEN 'Sherpa 語音辨識（本機）'
  WHEN 'ASR_OpenaiASR' THEN 'OpenAI 語音辨識'
  WHEN 'ASR_GroqASR' THEN 'Groq 語音辨識'
  WHEN 'ASR_VoskASR' THEN 'Vosk 離線語音辨識'
  WHEN 'ASR_Qwen3Flash' THEN 'Qwen3-ASR-Flash 語音辨識'
  WHEN 'Memory_nomem' THEN '不使用記憶'
  WHEN 'Memory_mem_local_short' THEN '本機短期記憶（摘要）'
  WHEN 'Memory_mem_report_only' THEN '僅回報聊天紀錄（不產生摘要）'
  WHEN 'Memory_mem0ai' THEN 'Mem0AI 記憶'
  WHEN 'Memory_powermem' THEN 'PowerMem 記憶'
  WHEN 'TTS_EdgeTTS' THEN 'Edge TTS 語音合成'
  WHEN 'TTS_HuoshanDoubleStreamTTS' THEN '火山引擎串流語音合成'
  WHEN 'TTS_AliBLStreamTTS' THEN '阿里百鍊串流語音合成'
  WHEN 'TTS_XunFeiStreamTTS' THEN '科大訊飛串流語音合成'
  WHEN 'TTS_MinimaxStreamTTS' THEN 'MiniMax 串流語音合成'
  WHEN 'TTS_AliyunStreamTTS' THEN '阿里雲串流語音合成'
  WHEN 'TTS_IndexStreamTTS' THEN 'Index-TTS 串流語音合成'
  WHEN 'TTS_PaddleSpeechTTS' THEN 'PaddleSpeech 語音合成'
  WHEN 'TTS_DoubaoTTS' THEN '火山引擎語音合成'
  WHEN 'TTS_TencentTTS' THEN '騰訊語音合成'
  WHEN 'TTS_AliyunTTS' THEN '阿里雲語音合成'
  WHEN 'TTS_OpenAITTS' THEN 'OpenAI 語音合成'
  WHEN 'TTS_CosyVoiceSiliconflow' THEN '硅基流動語音合成'
  WHEN 'TTS_CozeCnTTS' THEN 'Coze 中文語音合成'
  WHEN 'TTS_FishSpeech' THEN 'FishSpeech 語音合成'
  WHEN 'TTS_HSDSTTS_V2' THEN '火山引擎語音合成 2.0（串流）'
  WHEN 'TTS_TTS302AI' THEN '302AI 語音合成'
  WHEN 'TTS_VolcesAiGatewayTTS' THEN '火山引擎邊緣大模型閘道'
  WHEN 'TTS_CustomTTS' THEN '自訂語音合成'
  WHEN 'VAD_SileroVAD' THEN 'Silero VAD 語音活動偵測'
  WHEN 'VLLM_ChatGLMVLLM' THEN '智譜視覺 AI'
  WHEN 'VLLM_QwenVLVLLM' THEN '通義千問視覺模型'
  ELSE `model_name`
END
WHERE `id` IN (
  'ASR_FunASR','ASR_FunASRServer','ASR_SherpaASR','ASR_OpenaiASR','ASR_GroqASR','ASR_VoskASR','ASR_Qwen3Flash',
  'Memory_nomem','Memory_mem_local_short','Memory_mem_report_only','Memory_mem0ai','Memory_powermem',
  'TTS_EdgeTTS','TTS_HuoshanDoubleStreamTTS','TTS_AliBLStreamTTS','TTS_XunFeiStreamTTS',
  'TTS_MinimaxStreamTTS','TTS_AliyunStreamTTS','TTS_IndexStreamTTS','TTS_PaddleSpeechTTS',
  'TTS_DoubaoTTS','TTS_TencentTTS','TTS_AliyunTTS','TTS_OpenAITTS','TTS_CosyVoiceSiliconflow',
  'TTS_CozeCnTTS','TTS_FishSpeech','TTS_HSDSTTS_V2','TTS_TTS302AI','TTS_VolcesAiGatewayTTS',
  'TTS_CustomTTS','VAD_SileroVAD','VLLM_ChatGLMVLLM','VLLM_QwenVLVLLM'
);
