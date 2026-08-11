import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router';
import './assets/main.css';

// Global Touch / Click Ripple & Haptic Feedback
if (typeof window !== 'undefined') {
  const triggerHapticAndRipple = (e) => {
    const clickable = e.target.closest('button, .btn, .btn-icon, .btn-icon-sm, .chip, .toggle, .btn-link, select');
    if (!clickable || clickable.disabled) return;

    // Haptic vibration feedback for mobile WebUI
    if (typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function') {
      try { navigator.vibrate(10); } catch {}
    }

    // Dynamic Ripple Effect
    const rect = clickable.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height);
    const x = e.clientX - rect.left - size / 2;
    const y = e.clientY - rect.top - size / 2;

    const ripple = document.createElement('span');
    ripple.className = 'ripple-wave';
    ripple.style.width = ripple.style.height = `${size}px`;
    ripple.style.left = `${x}px`;
    ripple.style.top = `${y}px`;

    clickable.appendChild(ripple);
    setTimeout(() => {
      ripple.remove();
    }, 550);
  };

  document.addEventListener('pointerdown', triggerHapticAndRipple, { passive: true });
}

const app = createApp(App);

app.use(createPinia());
app.use(router);

app.mount('#app');

