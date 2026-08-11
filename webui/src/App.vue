<template>
  <div class="app-shell">
    <header class="app-header">
      <div class="header-inner">
        <div class="header-brand">
          <img :src="logoBase64" alt="PicoClaw" class="brand-logo" />
          <span class="brand-name">PicoClaw</span>
          <span class="brand-badge" :class="store.isRunning ? 'badge-ok' : 'badge-off'">
            {{ store.isRunning ? 'running' : 'stopped' }}
          </span>
        </div>
        <button
          @click="toggleTheme"
          class="btn-icon"
          :title="isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'"
        >
          <!-- Sun Icon (shown in Dark mode to switch to Light) -->
          <svg v-if="isDark" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="5"/>
            <line x1="12" y1="1" x2="12" y2="3"/>
            <line x1="12" y1="21" x2="12" y2="23"/>
            <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
            <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
            <line x1="1" y1="12" x2="3" y2="12"/>
            <line x1="21" y1="12" x2="23" y2="12"/>
            <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
            <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
          </svg>
          <!-- Moon Icon (shown in Light mode to switch to Dark) -->
          <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
          </svg>
        </button>
      </div>
    </header>

    <div v-if="store.errorMessage" class="toast toast-error">
      <span>{{ store.errorMessage }}</span>
      <button @click="store.errorMessage = ''" class="toast-close">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div v-if="store.toastMessage" class="toast toast-ok">
      <span>{{ store.toastMessage }}</span>
      <button @click="store.toastMessage = ''" class="toast-close">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>

    <main class="app-main">
      <router-view />
    </main>

    <footer class="app-footer">
      <div class="footer-inner">
        PicoClaw Module · {{ store.status.VERSION || '—' }}
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import { logoBase64 } from '@/assets/logo-b64.js';

const store = usePicoClawStore();
const isDark = ref(true);

function applyTheme(dark) {
  isDark.value = dark;
  if (dark) {
    document.documentElement.removeAttribute('data-theme');
  } else {
    document.documentElement.setAttribute('data-theme', 'light');
  }
  try {
    localStorage.setItem('picoclaw_theme', dark ? 'dark' : 'light');
  } catch {}
}

function toggleTheme() {
  applyTheme(!isDark.value);
}

let intervalId = null;

onMounted(() => {
  const saved = localStorage.getItem('picoclaw_theme');
  if (saved === 'light') {
    applyTheme(false);
  } else {
    applyTheme(true);
  }

  store.refresh();
  intervalId = setInterval(() => {
    if (!document.hidden && !store.busy) {
      store.refresh({ quiet: true });
    }
  }, 10000);
});

onUnmounted(() => {
  if (intervalId) clearInterval(intervalId);
});
</script>
