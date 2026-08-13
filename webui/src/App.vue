<template>
  <div id="app" class="min-h-screen flex flex-col bg-background text-on-background overflow-hidden">
    <header class="sticky top-0 z-10 bg-background border-b border-surface-container">
      <div class="max-w-3xl mx-auto px-5 py-3 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <img :src="logoBase64" alt="PicoClaw" class="w-8 h-8 rounded-md" />
          <span class="font-bold text-lg">PicoClaw</span>
          <span
            class="text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full"
            :class="store.isRunning ? 'bg-primary/20 text-primary border border-primary/30' : 'bg-error/20 text-error border border-error/30'"
          >
            {{ store.isRunning ? 'Running' : 'Stopped' }}
          </span>
        </div>
      </div>
    </header>

    <div v-if="store.errorMessage" class="mx-4 mt-2 p-3 bg-error/10 border border-error/20 text-error text-sm rounded-xl flex justify-between z-20">
      <span>{{ store.errorMessage }}</span>
      <button @click="store.errorMessage = ''" class="opacity-70 hover:opacity-100">✕</button>
    </div>
    <div v-if="store.toastMessage" class="mx-4 mt-2 p-3 bg-primary/10 border border-primary/20 text-primary text-sm rounded-xl flex justify-between z-20">
      <span>{{ store.toastMessage }}</span>
      <button @click="store.toastMessage = ''" class="opacity-70 hover:opacity-100">✕</button>
    </div>

    <main class="flex-1 overflow-hidden relative">
      <router-view />
    </main>

    <Navigation />
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import { logoBase64 } from '@/assets/logo-b64.js';
import Navigation from '@/components/ui/Navigation.vue';

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
