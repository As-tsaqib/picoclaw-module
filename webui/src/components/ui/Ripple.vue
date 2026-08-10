<template>
  <div
    ref="container"
    class="ripple-wrapper"
    @pointerdown="handlePointerDown"
    @keydown="handleKeydown"
    :tabindex="tabindex"
  >
    <slot></slot>
  </div>
</template>

<script setup>
import { ref } from 'vue';

defineProps({
  tabindex: {
    type: [String, Number],
    default: '0',
  },
  color: {
    type: String,
    default: 'rgba(255, 255, 255, 0.2)',
  },
});

const container = ref(null);

function handlePointerDown(event) {
  const el = container.value;
  if (!el) return;
  const rect = el.getBoundingClientRect();
  const size = Math.max(rect.width, rect.height);
  const x = event.clientX - rect.left - size / 2;
  const y = event.clientY - rect.top - size / 2;

  const ripple = document.createElement('span');
  ripple.className = 'ripple-effect';
  ripple.style.cssText = `
    width: ${size}px;
    height: ${size}px;
    left: ${x}px;
    top: ${y}px;
  `;

  el.appendChild(ripple);

  const cleanup = () => {
    ripple.classList.add('fade-out');
    setTimeout(() => ripple.remove(), 400);
    document.removeEventListener('pointerup', cleanup);
    document.removeEventListener('pointercancel', cleanup);
    el.removeEventListener('pointerleave', cleanup);
  };

  document.addEventListener('pointerup', cleanup);
  document.addEventListener('pointercancel', cleanup);
  el.addEventListener('pointerleave', cleanup);
}

function handleKeydown(event) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault();
    container.value?.click();
  }
}
</script>

<style scoped>
.ripple-wrapper {
  position: relative;
  overflow: hidden;
  outline: none;
  border: none;
}
</style>

<style>
.ripple-effect {
  position: absolute;
  border-radius: 50%;
  transform: scale(0);
  background-color: rgba(255, 255, 255, 0.18);
  pointer-events: none;
  animation: ripple-anim 0.45s ease-out forwards;
}

.ripple-effect.fade-out {
  opacity: 0;
  transition: opacity 0.3s ease;
}

@keyframes ripple-anim {
  to {
    transform: scale(2.8);
  }
}
</style>
