<template>
  <div class="space-y-4">
    <!-- Header Card -->
    <div class="glass-card rounded-3xl p-5 space-y-3">
      <div class="flex items-center gap-3">
        <div class="w-8 h-8 rounded-xl bg-primary/20 border border-primary/40 flex items-center justify-center text-primary font-bold">
          ⚡
        </div>
        <div>
          <h2 class="text-base font-black tracking-tight text-on-surface">Console AI Agent</h2>
          <p class="text-xs text-on-surface-variant font-medium">Uji & jalankan instruksi prompt ke picoclaw-agent secara realtime</p>
        </div>
      </div>

      <!-- Quick Preset Prompt Chips -->
      <div class="flex flex-wrap gap-2 pt-1">
        <Ripple
          v-for="preset in presets"
          :key="preset"
          @click="promptText = preset"
          class="text-xs py-1.5 px-3 rounded-xl bg-surface-container-highest/60 hover:bg-surface-container-highest text-on-surface-variant hover:text-on-surface border border-white/5 cursor-pointer font-medium transition-all active:scale-95"
        >
          {{ preset }}
        </Ripple>
      </div>

      <!-- Input Textarea Container -->
      <div class="relative mt-2">
        <textarea
          v-model="promptText"
          rows="3"
          placeholder="Ketik instruksi prompt di sini..."
          class="w-full bg-surface-container-lowest/80 border border-white/10 rounded-2xl p-3.5 text-xs text-on-surface placeholder:text-on-surface-variant/40 focus:outline-none focus:border-primary/60 transition-all resize-none font-sans"
        ></textarea>
        <button
          v-if="promptText"
          @click="promptText = ''"
          class="absolute top-3 right-3 text-xs text-on-surface-variant hover:text-on-surface p-1"
        >
          ✕
        </button>
      </div>

      <!-- Submit Action Button -->
      <div class="flex justify-end pt-1">
        <Ripple
          class="bg-gradient-to-r from-primary to-indigo-600 text-on-primary font-extrabold text-xs py-2.5 px-6 rounded-xl cursor-pointer shadow-lg hover:shadow-primary/30 flex items-center gap-2 active:scale-95 transition-all"
          :class="{ 'opacity-40 pointer-events-none': loading || !promptText.trim() }"
          @click="runPrompt"
        >
          <span v-if="loading" class="animate-spin text-sm">🔄</span>
          <span>{{ loading ? 'Memproses Prompt...' : '▶ Kirim Prompt' }}</span>
        </Ripple>
      </div>
    </div>

    <!-- Response Output Glass Card -->
    <div v-if="output || loadingError" class="glass-card rounded-3xl p-5 space-y-3">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="text-xs font-black uppercase tracking-wider text-on-surface-variant">Hasil Respons Agent</span>
          <span v-if="execTime" class="text-[0.65rem] px-2 py-0.5 rounded-full bg-primary/10 text-primary font-mono font-bold">
            {{ execTime }} ms
          </span>
        </div>
        <button
          @click="copyOutput"
          class="text-xs font-bold text-primary hover:underline flex items-center gap-1"
        >
          <span>{{ copied ? '✓ Tersalin!' : '📋 Salin Output' }}</span>
        </button>
      </div>

      <!-- Error Box -->
      <div v-if="loadingError" class="p-4 bg-rose-950/60 border border-rose-800/50 rounded-2xl text-rose-200 text-xs font-mono">
        {{ loadingError }}
      </div>

      <!-- Output Code Box -->
      <div v-else class="relative">
        <pre
          class="p-4 bg-surface-container-lowest/90 border border-white/5 rounded-2xl text-xs font-mono text-emerald-300/90 leading-relaxed whitespace-pre-wrap overflow-x-auto max-h-[50vh] scrollbar-hidden"
        >{{ output }}</pre>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import * as KSU from '@/helpers/KernelSU';
import Ripple from '@/components/ui/Ripple.vue';

const store = usePicoClawStore();
const promptText = ref('Halo PicoClaw, berikan ringkasan singkat statusmu.');
const output = ref('');
const loading = ref(false);
const loadingError = ref('');
const copied = ref(false);
const execTime = ref(0);

const presets = [
  'Halo PicoClaw',
  'Ringkaskan status sistem Android ini',
  'Fitur utama PicoClaw apa saja?',
];

async function runPrompt() {
  if (!promptText.value.trim() || loading.value) return;
  loading.value = true;
  loadingError.value = '';
  output.value = '';
  execTime.value = 0;

  const startTime = Date.now();
  try {
    const cmd = `/data/adb/modules/picoclaw/bin/picoclaw agent ${promptText.value.trim()}`;
    await store.control('status');
    const execRes = await KSU.exec(`su -c '${cmd.replaceAll("'", "'\\''")}'`);
    execTime.value = Date.now() - startTime;
    if (execRes.errno !== 0 && !execRes.stdout) {
      throw new Error(execRes.stderr || `Agent gagal (${execRes.errno})`);
    }
    output.value = execRes.stdout.trim() || execRes.stderr.trim() || 'Prompt dieksekusi tanpa return output.';
  } catch (err) {
    loadingError.value = err.message;
  } finally {
    loading.value = false;
  }
}

function copyOutput() {
  if (!output.value) return;
  navigator.clipboard.writeText(output.value);
  copied.value = true;
  setTimeout(() => (copied.value = false), 2000);
}
</script>
