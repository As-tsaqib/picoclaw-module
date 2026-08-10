<template>
  <label class="relative inline-flex items-center cursor-pointer select-none">
    <input
      type="checkbox"
      :checked="modelValue"
      :disabled="disabled"
      @change="$emit('update:modelValue', $event.target.checked)"
      class="sr-only peer"
    />
    <div
      class="w-13 h-7 bg-surface-variant rounded-full peer peer-checked:bg-primary transition-colors duration-200 ease-in-out peer-disabled:opacity-40"
    ></div>
    <div
      class="absolute left-1 top-1 w-5 h-5 bg-on-surface rounded-full transition-transform duration-200 ease-in-out peer-checked:translate-x-6 peer-checked:bg-on-primary"
    ></div>
  </label>
</template>

<script setup>
defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['update:modelValue']);
</script>
