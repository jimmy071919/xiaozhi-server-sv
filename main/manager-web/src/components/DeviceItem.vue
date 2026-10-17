<template>
  <div class="device-item">
    <div style="display: flex;justify-content: space-between;">
    <el-tooltip :content="device.agentName" placement="top" effect="light">
      <div class="device-item-title">
        {{ device.agentName }}
      </div>
    </el-tooltip>
      <div>
        <button class="icon-action icon-action--danger" type="button" aria-label="刪除" @click.stop="handleDelete">
          <i class="el-icon-delete"></i>
        </button>
        <el-tooltip class="item" effect="light" :content="device.systemPrompt" placement="top"
          popper-class="device-item-tooltip"> 
          <button class="icon-action" type="button" aria-label="資訊"><i class="el-icon-info"></i></button>
        </el-tooltip>
      </div>
    </div>
    <div class="device-name">
      {{ $t('home.languageModel') }}：{{ device.llmModelName }}
    </div>
    <div class="device-name">
      {{ $t('home.voiceModel') }}：{{ device.ttsModelName }} ({{ device.ttsVoiceName }})
    </div>
    <div style="display: flex;gap: 10px;align-items: center;">
      <div class="settings-btn" @click="handleConfigure">
        {{ $t('home.configureRole') }}
      </div>
      <div v-if="featureStatus.voiceprintRecognition" class="settings-btn" @click="handleVoicePrint">
        {{ $t('home.voiceprintRecognition') }}
      </div>
      <div class="settings-btn" @click="handleDeviceManage">
        {{ $t('home.deviceManagement') }}({{ device.deviceCount }})
      </div>
      <div :class="['settings-btn', { 'disabled-btn': device.memModelId === 'Memory_nomem' }]"
        @click="handleChatHistory">
        <el-tooltip effect="light" v-if="device.memModelId === 'Memory_nomem'" :content="$t('home.enableMemory')" placement="top">
          <span>{{ $t('home.chatHistory') }}</span>
        </el-tooltip>
        <span v-else>{{ $t('home.chatHistory') }}</span>
      </div>
    </div>
    <div class="version-info">
      <div>{{ $t('home.lastConversation') }}：{{ formattedLastConnectedTime }}</div>
      <el-tooltip :content="tags.join()" placement="top" effect="light">
        <div class="version-info-scroll">
          {{ tags.join() }}
        </div>
      </el-tooltip>
    </div>
  </div>
</template>

<script>
import i18n from '@/i18n';

export default {
  name: 'DeviceItem',
  props: {
    device: { type: Object, required: true },
    featureStatus: { 
      type: Object, 
      default: () => ({
        voiceprintRecognition: false,
        voiceClone: false,
        knowledgeBase: false
      })
    }
  },
  data() {
    return { switchValue: false }
  },
  computed: {
    formattedLastConnectedTime() {
      if (!this.device.lastConnectedAt) return this.$t('home.noConversation');

      const lastTime = new Date(this.device.lastConnectedAt);
      const now = new Date();
      const diffMinutes = Math.floor((now - lastTime) / (1000 * 60));

      if (diffMinutes <= 1) {
        return this.$t('home.justNow');
      } else if (diffMinutes < 60) {
        return this.$t('home.minutesAgo', { minutes: diffMinutes });
      } else if (diffMinutes < 24 * 60) {
        const hours = Math.floor(diffMinutes / 60);
        const minutes = diffMinutes % 60;
        return this.$t('home.hoursAgo', { hours, minutes });
      } else {
        return this.device.lastConnectedAt;
      }
    },
    tags() {
      if (!this.device.tags) return [];
      return this.device.tags.map((tag) => tag.tagName);
    }
  },
  methods: {
    handleDelete() {
      this.$emit('delete', this.device)
    },
    handleConfigure() {
      this.$router.push({ path: '/role-config', query: { agentId: this.device.agentId } });
    },
    handleVoicePrint() {
      this.$router.push({ path: '/voice-print', query: { agentId: this.device.agentId } });
    },
    handleDeviceManage() {
      this.$router.push({ path: '/device-management', query: { agentId: this.device.agentId } });
    },
    handleChatHistory() {
      if (this.device.memModelId === 'Memory_nomem') {
        return
      }
      this.$emit('chat-history', { agentId: this.device.agentId, agentName: this.device.agentName })
    }
  },
}
</script>
<style lang="scss" scoped>
.device-item {
  width: 342px;
  border-radius: 20px;
  background: #fafcfe;
  padding: 22px 22px 14px;
  box-sizing: border-box;
  &-title {
    flex: 1;
    font-weight: bold;
    font-size: 18px;
    color: #3d4566;
    text-align: left;
    text-overflow: ellipsis;
    white-space: nowrap;
    overflow: hidden;
  }
}

.icon-action {
  width: 30px;
  height: 30px;
  padding: 0;
  color: #6b7280;
  background: transparent;
  border: 0;
  border-radius: 7px;
  cursor: pointer;
  transition: background .2s ease, color .2s ease;
}

.icon-action:hover { color: #2563eb; background: #eff6ff; }
.icon-action--danger:hover { color: #dc2626; background: #fef2f2; }

.device-name {
  margin: 7px 0 10px;
  font-weight: 400;
  font-size: 11px;
  color: #3d4566;
  text-align: left;
}

.settings-btn {
  font-weight: 500;
  font-size: 12px;
  color: #5778ff;
  background: #e6ebff;
  width: auto;
  padding: 0 12px;
  height: 21px;
  line-height: 21px;
  cursor: pointer;
  border-radius: 14px;
}

.version-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 15px;
  font-size: 12px;
  color: #979db1;
  font-weight: 400;
  &-scroll {
    margin-left: 20px;
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    text-wrap: nowrap;
    text-align: right;
  }
}

.more-tag {
  cursor: pointer;
  flex-shrink: 0;
}

.all-tags-popover {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.disabled-btn {
  background: #e6e6e6;
  color: #999;
  cursor: not-allowed;
}
</style>

<style>
.device-item-tooltip {
  max-height: 60vh !important;
  max-width: 400px !important;
  overflow-y: auto !important;
  scrollbar-width: thin;
  word-break: break-word;
}

.device-item-tooltip .popper__arrow {
  display: none !important;
}

.device-item-tooltip[x-placement^="top"] .popper__arrow {
  border-top-color: transparent !important;
}

.device-item-tooltip[x-placement^="bottom"] .popper__arrow {
  border-bottom-color: transparent !important;
}
</style>
