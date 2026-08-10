<template>
  <div class="space-y-4">
    <!-- Hero Status Card -->
    <div class="glass-card relative overflow-hidden rounded-3xl p-5 border border-white/10 bg-gradient-to-br from-indigo-950/40 via-surface-container to-surface-container-high">
      <div class="relative z-10 flex items-start justify-between">
        <div class="flex items-center gap-3.5">
          <!-- Animated Status Ring -->
          <div class="relative flex items-center justify-center">
            <span
              v-if="store.isRunning"
              class="animate-ping absolute inline-flex h-7 w-7 rounded-full bg-emerald-400 opacity-75"
            ></span>
            <div
              class="relative w-4 h-4 rounded-full transition-all duration-300"
              :class="store.isRunning ? 'bg-emerald-400 shadow-[0_0_15px_rgba(52,211,153,0.9)]' : 'bg-rose-500 shadow-[0_0_10px_rgba(244,63,94,0.5)]'"
            ></div>
          </div>
          <div>
            <div class="flex items-center gap-2">
              <h2 class="text-lg font-black tracking-tight text-on-surface">
                {{ store.isRunning ? 'Launcher Service Aktif' : 'Launcher Service Berhenti' }}
              </h2>
            </div>
            <p class="text-xs text-on-surface-variant mt-0.5 font-medium">
              {{ store.isRunning ? `PID ${store.status.PID} · http://127.0.0.1:${store.status.PORT}` : 'Tekan Start untuk menjalankan dashboard web' }}
            </p>
          </div>
        </div>

        <span
          class="text-[0.65rem] font-black uppercase tracking-wider px-3 py-1 rounded-full border backdrop-blur-md"
          :class="store.isRunning ? 'bg-emerald-950/80 text-emerald-300 border-emerald-500/40' : 'bg-rose-950/80 text-rose-300 border-rose-500/40'"
        >
          {{ store.isRunning ? 'RUNNING' : 'STOPPED' }}
        </span>
      </div>

      <!-- Hero Action Area -->
      <div class="relative z-10 mt-5 space-y-2.5">
        <!-- Main Open Dashboard Button -->
        <Ripple
          class="w-full bg-gradient-to-r from-primary via-indigo-500 to-secondary text-on-primary font-black text-sm py-3 px-5 rounded-2xl text-center cursor-pointer shadow-[0_4px_25px_rgba(99,102,241,0.35)] hover:shadow-[0_4px_35px_rgba(99,102,241,0.55)] active:scale-98 transition-all flex items-center justify-center gap-2"
          @click="openDashboard"
        >
          <span>🚀 Buka Dashboard Web</span>
          <span class="text-xs opacity-80">↗</span>
        </Ripple>

        <!-- Secondary Control Buttons Grid -->
        <div class="grid grid-cols-3 gap-2">
          <Ripple
            class="bg-surface-container-highest/80 hover:bg-surface-container-highest border border-white/5 text-on-surface text-center py-2.5 px-3 rounded-xl font-bold cursor-pointer text-xs transition-all flex items-center justify-center gap-1.5"
            :class="{ 'opacity-40 pointer-events-none': store.isRunning || store.busy }"
            @click="store.executeAction('start')"
          >
            <span>▶</span> Start
          </Ripple>
          <Ripple
            class="bg-surface-container-highest/80 hover:bg-surface-container-highest border border-white/5 text-on-surface text-center py-2.5 px-3 rounded-xl font-bold cursor-pointer text-xs transition-all flex items-center justify-center gap-1.5"
            :class="{ 'opacity-40 pointer-events-none': !store.isRunning || store.busy }"
            @click="store.executeAction('stop')"
          >
            <span>⏹</span> Stop
          </Ripple>
          <Ripple
            class="bg-surface-container-highest/80 hover:bg-surface-container-highest border border-white/5 text-on-surface text-center py-2.5 px-3 rounded-xl font-bold cursor-pointer text-xs transition-all flex items-center justify-center gap-1.5"
            :class="{ 'opacity-40 pointer-events-none': store.busy }"
            @click="store.executeAction('restart')"
          >
            <span>🔄</span> Restart
          </Ripple>
        </div>
      </div>
    </div>

    <!-- Specs Matrix Cards Grid -->
    <div class="grid grid-cols-2 gap-3">
      <div class="glass-card glass-card-hover rounded-2xl p-4 space-y-1">
        <div class="flex items-center justify-between">
          <span class="text-[0.65rem] font-extrabold uppercase tracking-wider text-on-surface-variant">Versi Modul</span>
          <span class="text-xs">📦</span>
        </div>
        <div class="text-base font-black text-on-surface truncate">{{ store.status.VERSION || '—' }}</div>
      </div>

      <div class="glass-card glass-card-hover rounded-2xl p-4 space-y-1">
        <div class="flex items-center justify-between">
          <span class="text-[0.65rem] font-extrabold uppercase tracking-wider text-on-surface-variant">Upstream Tag</span>
          <span class="text-xs">🏷️</span>
        </div>
        <div class="text-base font-black text-on-surface truncate">{{ store.status.UPSTREAM || '—' }}</div>
      </div>

      <div class="glass-card glass-card-hover rounded-2xl p-4 space-y-1">
        <div class="flex items-center justify-between">
          <span class="text-[0.65rem] font-extrabold uppercase tracking-wider text-on-surface-variant">Port Lokal</span>
          <span class="text-xs">🌐</span>
        </div>
        <div class="text-base font-black text-primary truncate">{{ store.status.PORT || '18800' }}</div>
      </div>

      <div class="glass-card glass-card-hover rounded-2xl p-4 space-y-1">
        <div class="flex items-center justify-between">
          <span class="text-[0.65rem] font-extrabold uppercase tracking-wider text-on-surface-variant">Wrapper Termux</span>
          <span class="text-xs">⚡</span>
        </div>
        <div class="text-base font-black truncate" :class="store.status.WRAPPERS === 'ready' ? 'text-emerald-400' : 'text-amber-400'">
          {{ wrapperLabel(store.status.WRAPPERS) }}
        </div>
      </div>
    </div>

    <!-- System Path Shortcuts Card -->
    <div class="glass-card rounded-2xl p-4 space-y-3">
      <h3 class="text-xs font-black uppercase tracking-wider text-on-surface-variant flex items-center gap-2">
        <span>📂</span> Direktori & Lokasi Penting
      </h3>
      <div class="space-y-2 text-xs">
        <div class="flex items-center justify-between p-2.5 rounded-xl bg-surface-container-lowest border border-white/5">
          <div>
            <div class="font-bold text-on-surface">Data & Workspace</div>
            <code class="text-[0.7rem] text-primary font-mono">/data/adb/picoclaw</code>
          </div>
          <button @click="copyText('/data/adb/picoclaw')" class="text-xs text-on-surface-variant hover:text-primary">📋</button>
        </div>
        <div class="flex items-center justify-between p-2.5 rounded-xl bg-surface-container-lowest border border-white/5">
          <div>
            <div class="font-bold text-on-surface">File Log Service</div>
            <code class="text-[0.7rem] text-primary font-mono">{{ store.status.LOG }}</code>
          </div>
          <button @click="copyText(store.status.LOG)" class="text-xs text-on-surface-variant hover:text-primary">📋</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { usePicoClawStore } from '@/stores/PicoClawStore';
import Ripple from '@/components/ui/Ripple.vue';

const store = usePicoClawStore();

function wrapperLabel(val) {
  if (val === 'ready') return 'Ready (17 CLI)';
  if (val === 'missing') return 'Belum Dipasang';
  if (val === 'termux-not-found') return 'Termux Tidak Ada';
  if (val?.startsWith('partial-')) return `Partial (${val.slice(8).replace('-of-', '/')})`;
  return val || '—';
}

async function openDashboard() {
  if (!store.isRunning) {
    await store.executeAction('start');
    await new Promise((res) => setTimeout(res, 600));
  }
  const url = await store.control('url');
  window.location.assign(url);
}

function copyText(txt) {
  if (!txt) return;
  navigator.clipboard.writeText(txt);
  store.toastMessage = 'Teks disalin ke clipboard!';
}
</script>
