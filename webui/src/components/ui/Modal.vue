<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 overflow-y-auto backdrop-blur-sm"
        @click.self="closeOnOverlay && $emit('close')"
      >
        <Transition name="modal-slide">
          <div
            v-if="show"
            ref="panelRef"
            class="w-full max-w-sm bg-surface-container border border-outline-variant rounded-2xl p-5 text-on-surface mx-auto shadow-2xl"
          >
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-[15px] font-semibold m-0">{{ title }}</h3>
              <button @click="$emit('close')" class="w-8 h-8 rounded-lg border-none bg-surface-container-high hover:bg-surface-container-highest text-on-surface-variant flex items-center justify-center cursor-pointer transition-colors">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              </button>
            </div>
            <div class="mb-4">
              <slot></slot>
            </div>
            <div v-if="$slots.actions" class="flex justify-end gap-2 mt-4">
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
.modal-fade-enter-active,
.modal-fade-leave-active { transition: opacity 0.2s ease; }
.modal-fade-enter-from,
.modal-fade-leave-to { opacity: 0; }

.modal-slide-enter-active,
.modal-slide-leave-active { transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.25s ease; }
.modal-slide-enter-from,
.modal-slide-leave-to { transform: scale(0.95) translateY(10px); opacity: 0; }
</style>
