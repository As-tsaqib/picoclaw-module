<template>
  <div
    class="relative inline-flex items-center cursor-pointer"
    @click="toggle"
    :class="{ 'opacity-50 pointer-events-none': disabled }"
  >
    <div
      class="w-11 h-6 bg-surface-container-high rounded-full border border-outline-variant transition-colors"
      :class="{ 'bg-primary border-primary': modelValue }"
    ></div>
    <div
      class="absolute left-1 top-1 bg-on-surface w-4 h-4 rounded-full transition-transform"
      :class="{ 'transform translate-x-5 bg-on-primary': modelValue }"
    ></div>
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
});
const emit = defineEmits(['update:modelValue']);

function toggle() {
  if (!props.disabled) emit('update:modelValue', !props.modelValue);
}
</script>
