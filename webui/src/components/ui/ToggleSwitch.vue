<template>
  <button
    type="button"
    class="toggle-switch relative inline-flex items-center shrink-0"
    role="switch"
    :aria-checked="displayValue"
    :aria-label="label"
    :disabled="disabled"
    :class="{ 'is-dragging': dragging }"
    @pointerdown="startDrag"
    @pointermove="moveDrag"
    @pointerup="endDrag"
    @pointercancel="cancelDrag"
    @click="toggle"
  >
    <span
      class="toggle-track w-11 h-6 bg-surface-container-high rounded-full border border-outline-variant"
      :class="{ 'is-on': displayValue }"
      aria-hidden="true"
    >
      <span
        class="toggle-thumb absolute left-1 top-1 bg-on-surface w-4 h-4 rounded-full"
        :class="{ 'is-on': displayValue }"
        :style="thumbStyle"
      ></span>
    </span>
  </button>
</template>

<script setup>
import { computed, ref, watch } from 'vue';

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
  label: { type: String, default: 'Toggle setting' },
});
const emit = defineEmits(['update:modelValue']);

const settledValue = ref(props.modelValue);
const dragValue = ref(props.modelValue);
const dragOffset = ref(props.modelValue ? 20 : 0);
const dragStartX = ref(0);
const dragStartOffset = ref(0);
const dragging = ref(false);
const dragMoved = ref(false);
const suppressClick = ref(false);

const displayValue = computed(() => dragging.value ? dragValue.value : settledValue.value);
const thumbStyle = computed(() => ({
  '--toggle-thumb-offset': `${dragging.value ? dragOffset.value : (displayValue.value ? 20 : 0)}px`,
}));

watch(() => props.modelValue, (value) => {
  settledValue.value = value;
  if (!dragging.value) {
    dragValue.value = value;
    dragOffset.value = value ? 20 : 0;
  }
});

function toggle() {
  if (suppressClick.value) {
    suppressClick.value = false;
    return;
  }
  if (props.disabled) return;
  const nextValue = !settledValue.value;
  settledValue.value = nextValue;
  emit('update:modelValue', nextValue);
}

function startDrag(event) {
  if (props.disabled || event.button > 0) return;
  dragging.value = true;
  dragMoved.value = false;
  dragStartX.value = event.clientX;
  dragStartOffset.value = settledValue.value ? 20 : 0;
  dragOffset.value = dragStartOffset.value;
  dragValue.value = settledValue.value;
  try { event.currentTarget.setPointerCapture(event.pointerId); } catch {}
}

function moveDrag(event) {
  if (!dragging.value) return;
  const delta = event.clientX - dragStartX.value;
  if (Math.abs(delta) > 3) {
    dragMoved.value = true;
    event.preventDefault();
  }
  const nextOffset = Math.max(0, Math.min(20, dragStartOffset.value + delta));
  dragOffset.value = nextOffset;
  dragValue.value = nextOffset >= 10;
}

function finishDrag(event, cancelled = false) {
  if (!dragging.value) return;
  try { event.currentTarget.releasePointerCapture(event.pointerId); } catch {}

  const didDrag = dragMoved.value;
  const nextValue = cancelled ? settledValue.value : dragValue.value;
  dragging.value = false;
  dragMoved.value = false;

  if (!didDrag) return;
  suppressClick.value = true;
  settledValue.value = nextValue;
  dragOffset.value = nextValue ? 20 : 0;
  if (nextValue !== props.modelValue) emit('update:modelValue', nextValue);
  window.setTimeout(() => { suppressClick.value = false; }, 0);
}

function endDrag(event) {
  finishDrag(event);
}

function cancelDrag(event) {
  finishDrag(event, true);
}
</script>

<style scoped>
.toggle-switch {
  width: 44px;
  height: 28px;
  padding: 1px;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: inherit;
  cursor: pointer;
  touch-action: manipulation;
  -webkit-user-select: none;
  user-select: none;
}

.toggle-switch:disabled {
  cursor: not-allowed;
  opacity: .5;
}

.toggle-track {
  position: relative;
  display: block;
  width: 100%;
  height: 24px;
  border-radius: 999px;
  transition: background-color 180ms cubic-bezier(.2, .8, .2, 1),
    border-color 180ms cubic-bezier(.2, .8, .2, 1),
    box-shadow 180ms cubic-bezier(.2, .8, .2, 1);
  will-change: background-color, border-color;
}

.toggle-track.is-on {
  background-color: var(--primary, #ffb0ccff);
  border-color: var(--primary, #ffb0ccff);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--primary, #ffb0ccff) 12%, transparent);
}

.toggle-thumb {
  display: block;
  transition: transform 220ms cubic-bezier(.2, .8, .2, 1),
    background-color 180ms cubic-bezier(.2, .8, .2, 1),
    box-shadow 180ms cubic-bezier(.2, .8, .2, 1);
  will-change: transform;
  box-shadow: 0 1px 2px rgb(0 0 0 / 24%);
  transform: translateX(var(--toggle-thumb-offset, 0px));
}

.toggle-switch.is-dragging .toggle-thumb {
  transition: background-color 120ms cubic-bezier(.2, .8, .2, 1),
    box-shadow 120ms cubic-bezier(.2, .8, .2, 1);
}

.toggle-thumb.is-on {
  background-color: var(--on-primary, #541d35ff);
  box-shadow: 0 1px 3px rgb(0 0 0 / 30%);
}

.toggle-switch:focus-visible {
  outline: 2px solid var(--primary, #ffb0ccff);
  outline-offset: 3px;
}

@media (prefers-reduced-motion: reduce) {
  .toggle-track,
  .toggle-thumb {
    transition-duration: 1ms;
  }
}
</style>
