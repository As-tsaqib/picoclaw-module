<template>
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-xs p-0 sm:p-4"
        @click.self="closeOnOverlay && $emit('close')"
      >
        <Transition name="slide-up">
          <div
            v-if="show"
            class="w-full max-w-lg bg-surface-container rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl border border-outline-variant text-on-surface"
          >
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-on-surface">{{ title }}</h3>
              <button
                @click="$emit('close')"
                class="w-8 h-8 rounded-full flex items-center justify-center bg-surface-variant text-on-surface-variant hover:bg-surface-container-high transition-colors"
              >
                ✕
              </button>
            </div>
            <div class="modal-body mb-6">
              <slot></slot>
            </div>
            <div v-if="$slots.actions" class="flex justify-end gap-3">
              <slot name="actions"></slot>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: '',
  },
  closeOnOverlay: {
    type: Boolean,
    default: true,
  },
});

defineEmits(['close']);
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
}

@media (min-width: 640px) {
  .slide-up-enter-from,
  .slide-up-leave-to {
    transform: scale(0.95) translateY(10px);
    opacity: 0;
  }
}
</style>
