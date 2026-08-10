<template>
  <div class="min-h-screen bg-background text-on-background flex flex-col font-sans antialiased selection:bg-primary/30 relative overflow-x-hidden">
    <!-- Ambient Background Neon Aura -->
    <div class="fixed top-0 right-0 w-96 h-96 bg-primary/10 rounded-full blur-[100px] pointer-events-none -z-10 animate-pulse"></div>
    <div class="fixed bottom-0 left-0 w-96 h-96 bg-secondary/10 rounded-full blur-[100px] pointer-events-none -z-10"></div>

    <!-- Floating Top Bar Header -->
    <header class="sticky top-0 z-30 bg-background/80 backdrop-blur-xl border-b border-white/5 px-4 py-3 pt-[calc(0.75rem+var(--window-inset-top,0px))]">
      <div class="max-w-xl mx-auto flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="relative">
            <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-primary via-indigo-500 to-secondary p-0.5 shadow-[0_0_20px_rgba(99,102,241,0.35)] flex items-center justify-center">
              <div class="w-full h-full bg-surface-container rounded-[14px] flex items-center justify-center">
                <span class="text-transparent bg-clip-text bg-gradient-to-br from-primary to-secondary font-black text-lg">P</span>
              </div>
            </div>
            <span
              class="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-background"
              :class="store.isRunning ? 'bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.8)]' : 'bg-rose-500'"
            ></span>
          </div>
          <div>
            <div class="flex items-center gap-2">
              <h1 class="text-base font-black tracking-tight text-on-surface">PicoClaw</h1>
              <span class="text-[0.62rem] font-bold px-2 py-0.5 rounded-full bg-primary/15 text-primary border border-primary/30 tracking-wider uppercase">
                KSU Module
              </span>
            </div>
            <p class="text-[0.72rem] text-on-surface-variant font-medium">Lightweight AI agent optimized for Android</p>
          </div>
        </div>

        <button
          @click="store.refresh()"
          class="w-9 h-9 rounded-xl bg-surface-container-high border border-white/10 flex items-center justify-center text-on-surface-variant hover:text-on-surface active:scale-95 transition-all"
          title="Refresh Status"
        >
          <span class="text-sm font-bold" :class="{ 'animate-spin': store.busy }">↻</span>
        </button>
      </div>
    </header>

    <!-- Floating Error / Toast Banner -->
    <div v-if="store.errorMessage" class="max-w-xl mx-auto px-4 pt-3 w-full">
      <div class="bg-rose-950/90 border border-rose-800/60 text-rose-200 px-4 py-3 rounded-2xl text-xs flex items-center justify-between shadow-xl backdrop-blur-md animate-bounce">
        <div class="flex items-center gap-2">
          <span class="text-base">⚠️</span>
          <span>{{ store.errorMessage }}</span>
        </div>
        <button @click="store.errorMessage = ''" class="ml-2 font-bold hover:text-white text-sm">✕</button>
      </div>
    </div>

    <!-- Toast Success Banner -->
    <div v-if="store.toastMessage" class="max-w-xl mx-auto px-4 pt-3 w-full">
      <div class="bg-emerald-950/90 border border-emerald-800/60 text-emerald-200 px-4 py-3 rounded-2xl text-xs flex items-center justify-between shadow-xl backdrop-blur-md">
        <div class="flex items-center gap-2">
          <span class="text-base">✓</span>
          <span>{{ store.toastMessage }}</span>
        </div>
        <button @click="store.toastMessage = ''" class="ml-2 font-bold hover:text-white text-sm">✕</button>
      </div>
    </div>

    <!-- Main View Area -->
    <main class="flex-1 max-w-xl mx-auto w-full p-4 pb-safe-nav overflow-y-auto">
      <router-view v-slot="{ Component }">
        <transition name="fade-page" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </main>

    <!-- Bottom Floating Navigation -->
    <Navigation />
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';
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

<style>
.fade-page-enter-active,
.fade-page-leave-active {
  transition: opacity 0.2s cubic-bezier(0.16, 1, 0.3, 1), transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}
.fade-page-enter-from {
  opacity: 0;
  transform: translateY(6px) scale(0.99);
}
.fade-page-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(0.99);
}
</style>
