<template>
  <div
    ref="container"
    class="ripple-wrapper"
    @pointerdown="handlePointerDown"
    @keydown="handleKeydown"
    :tabindex="tabindex"
    role="button"
    :aria-disabled="tabindex === -1 ? 'true' : undefined"
    :class="{ 'non-touch': !isTouchDevice }"
    :style="hoverStyle"
  >
    <slot></slot>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'

const props = defineProps({
  tabindex: {
    type: [String, Number],
    default: '0',
  },
  color: {
    type: String,
    default: null,
  },
})

const container = ref(null)
const isTouchDevice = ref(false)
const hoverBackgroundColor = ref('')

const hoverStyle = computed(() => {
  if (isTouchDevice.value || !hoverBackgroundColor.value) return {}
  return {
    '--hover-color': hoverBackgroundColor.value,
  }
})

onMounted(() => {
  detectTouchDevice()
  updateHoverColor()
})

function detectTouchDevice() {
  isTouchDevice.value =
    'ontouchstart' in window || navigator.maxTouchPoints > 0 || navigator.msMaxTouchPoints > 0
}

function updateHoverColor() {
  nextTick(() => {
    if (container.value) {
      hoverBackgroundColor.value = getHoverColor(container.value)
    }
  })
}

function handlePointerDown(event) {
  if (event.button !== 0 || !container.value) return
  const element = container.value
  const rect = element.getBoundingClientRect()
  if (!rect.width || !rect.height) return
  const size = Math.max(rect.width, rect.height)
  const x = event.clientX - rect.left - size / 2
  const y = event.clientY - rect.top - size / 2
  const duration = Math.min(0.52, Math.max(0.24, 0.24 + (rect.width / 800) * 0.2))

  if (typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function') {
    try { navigator.vibrate(8) } catch {}
  }

  const ripple = document.createElement('span')
  ripple.className = 'ripple'
  ripple.style.cssText = `
    width: ${size}px;
    height: ${size}px;
    left: ${x}px;
    top: ${y}px;
    animation-duration: ${duration}s;
    transition: opacity ${Math.min(0.24, duration * 0.55)}s ease;
    background-color: ${getRippleColor(element)};
  `

  element.appendChild(ripple)
  requestAnimationFrame(() => ripple.classList.add('is-live'))

  const cleanup = () => {
    if (!ripple.isConnected) return
    ripple.classList.add('end')
    setTimeout(() => ripple.remove(), Math.min(260, duration * 1000))
    document.removeEventListener('pointerup', cleanup)
    document.removeEventListener('pointercancel', cleanup)
    element.removeEventListener('pointerleave', cleanup)
  }

  document.addEventListener('pointerup', cleanup)
  document.addEventListener('pointercancel', cleanup)
  element.addEventListener('pointerleave', cleanup)
}

function handleKeydown(event) {
  if (!event.repeat && (event.key === 'Enter' || event.key === ' ')) {
    event.preventDefault()
    container.value.click()
  }
}

onBeforeUnmount(() => {
  if (!container.value) return
  container.value.querySelectorAll('.ripple').forEach((ripple) => ripple.remove())
})

function getRippleColor(el) {
  if (props.color) return props.color
  if (el.dataset.rippleColor) return el.dataset.rippleColor

  const currentColor = window.getComputedStyle(el).color
  if (currentColor && !currentColor.includes('rgba(0, 0, 0, 0)')) {
    return currentColor.replace('rgb', 'rgba').replace(')', ', 0.2)')
  }

  const bgColor = getBackgroundColor(el)
  return isDarkColor(bgColor) ? 'rgba(255, 255, 255, 0.2)' : 'rgba(0, 0, 0, 0.2)'
}

function getHoverColor(el) {
  if (props.color) {
    return adjustColorOpacity(props.color, 0.45)
  }
  if (el.dataset.rippleColor) {
    return adjustColorOpacity(el.dataset.rippleColor, 0.45)
  }

  const currentColor = window.getComputedStyle(el).color
  if (currentColor && !currentColor.includes('rgba(0, 0, 0, 0)')) {
    return currentColor.replace('rgb', 'rgba').replace(')', ', 0.09)')
  }

  const bgColor = getBackgroundColor(el)
  return isDarkColor(bgColor) ? 'rgba(255, 255, 255, 0.09)' : 'rgba(0, 0, 0, 0.09)'
}

function adjustColorOpacity(color, opacity) {
  if (color.startsWith('rgba')) {
    const matches = color.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/)
    if (matches) {
      return `rgba(${matches[1]}, ${matches[2]}, ${matches[3]}, ${opacity})`
    }
  } else if (color.startsWith('rgb')) {
    return color.replace('rgb', 'rgba').replace(')', `, ${opacity})`)
  } else if (color.startsWith('#')) {
    const hex = color.replace('#', '')
    const r = parseInt(hex.substring(0, 2), 16)
    const g = parseInt(hex.substring(2, 4), 16)
    const b = parseInt(hex.substring(4, 6), 16)
    return `rgba(${r}, ${g}, ${b}, ${opacity})`
  }
  return color
}

function getBackgroundColor(el) {
  let depth = 0,
    current = el
  while (current && current !== document.documentElement && depth < 10) {
    const bg = window.getComputedStyle(current).backgroundColor
    if (bg && !bg.includes('rgba(0, 0, 0, 0)') && bg !== 'transparent') {
      return bg
    }
    current = current.parentElement
    depth++
  }
  return 'rgb(255, 255, 255)'
}

function isDarkColor(colorStr) {
  const rgb = colorStr.match(/\d+/g)
  if (!rgb || rgb.length < 3) return false
  const [r, g, b] = rgb.map(Number)
  return r * 0.299 + g * 0.587 + b * 0.114 < 96
}
</script>

<style scoped>
.ripple-wrapper {
  position: relative;
  overflow: hidden;
  outline: none;
  isolation: isolate;
  transition: background-color 0.18s cubic-bezier(.2, .8, .2, 1),
    box-shadow 0.18s cubic-bezier(.2, .8, .2, 1),
    transform 0.16s cubic-bezier(.2, .8, .2, 1);
  touch-action: manipulation;
  will-change: transform;
}

.ripple-wrapper:active {
  transform: scale(.985);
}

.ripple-wrapper:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

.ripple-wrapper.non-touch::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: var(--hover-color);
  opacity: 0;
  transition: opacity 0.2s ease;
  pointer-events: none;
  border-radius: inherit;
}

.ripple-wrapper.non-touch:hover::before {
  opacity: 1;
}

.ripple-wrapper.non-touch:focus-visible::before {
  z-index: -1;
}
</style>

<style>
.ripple {
  position: absolute;
  border-radius: 50%;
  transform: scale(0);
  opacity: 0;
  animation: ripple-animation ease-out forwards;
  pointer-events: none;
  z-index: 0;
  will-change: transform, opacity;
}

.ripple.is-live {
  opacity: .42;
}

.ripple.end {
  opacity: 0;
}

@keyframes ripple-animation {
  to {
    transform: scale(2.4);
  }
}

@media (prefers-reduced-motion: reduce) {
  .ripple {
    animation-duration: 0.1s !important;
  }
  @keyframes ripple-animation {
    to {
      transform: scale(1.5);
    }
  }
}
</style>
