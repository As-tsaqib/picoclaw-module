<template>
  <div class="space-y-4">
    <!-- Log Controls Header Card -->
    <div class="glass-card rounded-3xl p-5 space-y-3">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="text-sm">📄</span>
          <div>
            <h2 class="text-base font-black tracking-tight text-on-surface">Log Service Launcher</h2>
            <p class="text-xs text-on-surface-variant font-medium mt-0.5">
              {{ filteredLines.length }} baris terurai
            </p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <select
            v-model="store.logLines"
            @change="store.refresh()"
            class="bg-surface-container-highest/80 border border-white/10 text-on-surface text-xs font-bold rounded-xl p-2 focus:outline-none"
          >
            <option value="50">50 baris</option>
            <option value="80">80 baris</option>
            <option value="150">150 baris</option>
            <option value="300">300 baris</option>
            <option value="500">500 baris</option>
          </select>
          <Ripple
            class="bg-rose-950/60 hover:bg-rose-900/80 text-rose-200 border border-rose-800/40 text-xs font-bold px-3 py-2 rounded-xl cursor-pointer active:scale-95 transition-all"
            @click="store.executeAction('clear-logs')"
          >
            Bersihkan
          </Ripple>
        </div>
      </div>

      <!-- Filter Search Bar -->
      <div class="relative">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Filter log (misal: WRN, ERR, launcher, PID)..."
          class="w-full bg-surface-container-lowest/80 border border-white/10 rounded-2xl px-3.5 py-2.5 text-xs text-on-surface placeholder:text-on-surface-variant/40 focus:outline-none focus:border-primary/60 font-sans"
        />
        <button
          v-if="searchQuery"
          @click="searchQuery = ''"
          class="absolute top-2.5 right-3 text-xs text-on-surface-variant hover:text-on-surface p-1"
        >
          ✕
        </button>
      </div>
    </div>

    <!-- Terminal Log Output Container -->
    <div class="glass-card rounded-3xl p-4 bg-surface-container-lowest/90 border border-white/10 overflow-hidden">
      <div
        ref="logContainer"
        class="font-mono text-[0.72rem] leading-relaxed max-h-[55vh] overflow-y-auto overflow-x-auto scrollbar-hidden space-y-1"
      >
        <template v-if="filteredLines.length">
          <div
            v-for="(line, idx) in filteredLines"
            :key="idx"
            class="flex items-start gap-3 hover:bg-white/5 py-0.5 px-1 rounded transition-colors"
          >
            <span class="text-on-surface-variant/40 select-none text-[0.65rem] font-mono min-w-[1.8rem] text-right">{{ idx + 1 }}</span>
            <span
              class="break-all"
              :class="lineColorClass(line)"
            >{{ line }}</span>
          </div>
        </template>
        <div v-else class="text-on-surface-variant/50 text-center py-8">
          Log kosong atau tidak cocok dengan pencarian.
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import Ripple from '@/components/ui/Ripple.vue';

const store = usePicoClawStore();
const searchQuery = ref('');
const logContainer = ref(null);

const filteredLines = computed(() => {
  if (!store.logs) return [];
  const lines = store.logs.split('\n').filter((l) => l.trim().length > 0);
  if (!searchQuery.value.trim()) return lines;
  const q = searchQuery.value.toLowerCase();
  return lines.filter((l) => l.toLowerCase().includes(q));
});

function lineColorClass(line) {
  if (line.includes('ERR') || line.includes('gagal') || line.includes('error')) return 'text-rose-400 font-semibold';
  if (line.includes('WRN') || line.includes('Warning')) return 'text-amber-300';
  if (line.includes('aktif') || line.includes('RUNNING') || line.includes('PID')) return 'text-emerald-300';
  return 'text-on-surface/90';
}

function scrollToBottom() {
  nextTick(() => {
    if (logContainer.value) {
      logContainer.value.scrollTop = logContainer.value.scrollHeight;
    }
  });
}

watch(() => store.logs, scrollToBottom);
onMounted(scrollToBottom);
</script>
