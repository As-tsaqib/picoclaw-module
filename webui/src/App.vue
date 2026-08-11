<template>
  <div class="app-shell">
    <header class="app-header">
      <div class="header-inner">
        <div class="header-brand">
          <span class="brand-mark">P</span>
          <span class="brand-name">PicoClaw</span>
          <span class="brand-badge" :class="store.isRunning ? 'badge-ok' : 'badge-off'">
            {{ store.isRunning ? 'running' : 'stopped' }}
          </span>
        </div>
        <button
          @click="store.refresh()"
          class="btn-icon"
          title="Refresh"
        >
          <svg :class="{ spinning: store.busy }" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 2v6h-6"/><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M3 22v-6h6"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/></svg>
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
import { onMounted, onUnmounted } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';

const store = usePicoClawStore();

let intervalId = null;

onMounted(() => {
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
