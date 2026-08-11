<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="show"
        class="modal-overlay"
        @click.self="closeOnOverlay && $emit('close')"
      >
        <Transition name="modal-slide">
          <div
            v-if="show"
            ref="panelRef"
            class="modal-panel"
          >
            <div class="modal-head">
              <h3 class="modal-title">{{ title }}</h3>
              <button @click="$emit('close')" class="modal-close">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              </button>
            </div>
            <div class="modal-content">
              <slot></slot>
            </div>
            <div v-if="$slots.actions" class="modal-actions">
              <slot name="actions"></slot>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, watch, nextTick, onUnmounted } from 'vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  title: { type: String, default: '' },
  closeOnOverlay: { type: Boolean, default: true },
});

defineEmits(['close']);

const panelRef = ref(null);

function onFocusIn(e) {
  if (!panelRef.value) return;
  if (!panelRef.value.contains(e.target)) return;
  setTimeout(() => {
    e.target.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, 300);
}

watch(() => props.show, (visible) => {
  nextTick(() => {
    if (visible) {
      document.addEventListener('focusin', onFocusIn);
    } else {
      document.removeEventListener('focusin', onFocusIn);
    }
  });
});

onUnmounted(() => {
  document.removeEventListener('focusin', onFocusIn);
});
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.55);
  padding: 16px;
  overflow-y: auto;
}

.modal-panel {
  width: 100%;
  max-width: 400px;
  background: var(--c-surface, #161b22);
  border: 1px solid var(--c-border, #2d333b);
  border-radius: 12px;
  padding: 20px;
  color: var(--c-text, #e6edf3);
  margin: auto;
}

.modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}

.modal-title {
  font-size: 15px;
  font-weight: 700;
  margin: 0;
}

.modal-close {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: var(--c-surface-hi, #1c2128);
  color: var(--c-text-dim, #7d8590);
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-close:hover { color: var(--c-text, #e6edf3); }

.modal-content { margin-bottom: 16px; }

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.modal-fade-enter-active,
.modal-fade-leave-active { transition: opacity 0.2s ease; }
.modal-fade-enter-from,
.modal-fade-leave-to { opacity: 0; }

.modal-slide-enter-active,
.modal-slide-leave-active { transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.25s ease; }
.modal-slide-enter-from,
.modal-slide-leave-to { transform: scale(0.95) translateY(10px); opacity: 0; }
</style>
