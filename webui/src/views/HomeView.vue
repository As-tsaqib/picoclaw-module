<template>
  <div class="scrollbar-hidden pb-safe-nav flex-1 min-h-0 overflow-y-scroll h-full">
    <div class="max-w-3xl mx-auto p-5 py-1">
      
      <!-- Daemon Status -->
      <div class="bg-secondary-container border border-outline-variant/30 mb-4 p-4 rounded-xl flex items-center gap-4 text-on-secondary-container">
        <Ripple
          @click="store.executeAction(store.isRunning ? 'stop' : 'start')"
          class="w-12 h-12 rounded-full flex items-center justify-center shrink-0 cursor-pointer transition-colors duration-200"
          :class="[
            store.isRunning ? 'bg-primary text-on-primary' : 'bg-surface-variant text-on-surface-variant',
            { 'opacity-50 pointer-events-none': store.busy }
          ]"
        >
          <Transition name="status-icon" mode="out-in">
            <!-- Play icon (saat berhenti) -->
            <svg v-if="!store.isRunning" key="play" class="w-6 h-6 ml-0.5" viewBox="0 0 24 24" fill="currentColor"><polygon points="6 3 20 12 6 21 6 3"></polygon></svg>
            <!-- Stop icon (saat aktif) -->
            <svg v-else key="stop" class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="12" height="14" rx="1"></rect></svg>
          </Transition>
        </Ripple>
        <div class="flex-1 flex flex-col">
          <span class="text-lg font-semibold">{{ store.isRunning ? 'Dashboard Aktif' : 'Dashboard Berhenti' }}</span>
          <span class="text-xs pt-1 block opacity-80">{{ store.isRunning ? `PID ${store.status.PID} · Port ${store.status.PORT}` : 'Ketuk tombol untuk memulai.' }}</span>
        </div>
      </div>

      <!-- Main Action (Open Dashboard) -->
      <Ripple
        @click="openDashboard"
        class="cursor-pointer text-on-primary bg-primary mb-4 p-4 rounded-xl w-full flex items-center justify-between"
      >
        <div>
          <h2 class="text-sm font-semibold mb-1">Buka Dashboard Web</h2>
          <p class="text-xs opacity-80">Akses antarmuka penuh PicoClaw di browser</p>
        </div>
        <span class="text-xl">
          <svg class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></polyline><line x1="10" y1="14" x2="21" y2="3"></line></svg>
        </span>
      </Ripple>

      <!-- Backup & Restore -->
      <div class="bg-surface-container border border-outline-variant/30 mb-4 p-4 rounded-xl text-on-surface">
        <h3 class="text-sm font-medium mb-3">Manajemen Konfigurasi</h3>
        <div class="grid grid-cols-2 gap-3">
          <Ripple
            @click="openBackupPicker"
            class="cursor-pointer bg-surface-container-high hover:bg-surface-container-highest p-3 rounded-lg flex flex-col gap-1 items-center justify-center"
            :class="{ 'opacity-50 pointer-events-none': store.busy }"
          >
            <span class="text-xl">
              <svg class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>
            </span>
            <span class="text-xs font-medium">Backup</span>
          </Ripple>
          <Ripple
            @click="openRestorePicker"
            class="cursor-pointer bg-surface-container-high hover:bg-surface-container-highest p-3 rounded-lg flex flex-col gap-1 items-center justify-center"
            :class="{ 'opacity-50 pointer-events-none': store.busy }"
          >
            <span class="text-xl">
              <svg class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
            </span>
            <span class="text-xs font-medium">Restore</span>
          </Ripple>
        </div>
      </div>


      <!-- Logs -->
      <div class="bg-surface-container border border-outline-variant/30 mb-4 p-4 rounded-xl flex flex-col h-[50vh] text-on-surface">
        <div class="flex justify-between items-center mb-3">
          <h3 class="text-sm font-medium">Service Logs</h3>
          <div class="flex items-center gap-2">
            <select v-model="store.logLines" @change="store.refresh()" class="bg-surface-container-high border-none text-xs rounded-md px-2 py-1 outline-none text-on-surface">
              <option value="50">50 Baris</option>
              <option value="100">100 Baris</option>
              <option value="300">300 Baris</option>
            </select>
            <Ripple @click="store.executeAction('clear-logs')" class="cursor-pointer bg-error/20 text-error px-3 py-1 rounded-md text-xs font-medium">
              Clear
            </Ripple>
          </div>
        </div>
        <input
          v-model="logSearch"
          type="text"
          placeholder="Filter logs..."
          class="bg-surface-container-high border border-outline-variant/30 text-xs px-3 py-2 rounded-lg outline-none focus:border-primary w-full mb-3 text-on-surface"
        />
        <div class="flex-1 overflow-auto bg-[#1e1e1e] border border-outline-variant/30 rounded-lg text-[#d4d4d4]" ref="logContainer">
          <pre v-if="filteredLogText" class="p-3 m-0" style="white-space: pre; overflow: visible; line-height: 1.2; letter-spacing: 0; font-size: 11px; font-family: 'DejaVu Sans Mono', monospace; width: max-content; min-width: 100%; tab-size: 8;">{{ filteredLogText }}</pre>
          <div v-else class="text-on-surface-variant flex h-full items-center justify-center italic">Tidak ada log.</div>
        </div>
      </div>

    </div>
  </div>

  <FilePickerModal
    :show="showFilePicker"
    :mode="pickerMode"
    initial-path="/sdcard/Download"
    @close="showFilePicker = false"
    @select="handlePickerSelection"
  />
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import * as KSU from '@/helpers/KernelSU';
import FilePickerModal from '@/components/ui/FilePickerModal.vue';
import Ripple from '@/components/ui/Ripple.vue';

const router = useRouter();
const store = usePicoClawStore();

const showFilePicker = ref(false);
const pickerMode = ref('file');

function openBackupPicker() {
  pickerMode.value = 'directory';
  showFilePicker.value = true;
}

function openRestorePicker() {
  pickerMode.value = 'file';
  showFilePicker.value = true;
}

function handlePickerSelection(selectedPath) {
  if (pickerMode.value === 'directory') {
    const timestamp = new Date().toISOString().replace(/[-:T.]/g, '').slice(0, 15);
    const dest = `${selectedPath.replace(/\/$/, '')}/picoclaw-backup-${timestamp}.tar.gz`;
    store.executeAction('backup', dest);
  } else if (pickerMode.value === 'file') {
    store.executeAction('restore', selectedPath);
  }
}

async function openDashboard() {
  if (!store.isRunning) {
    await store.executeAction('start');
    await new Promise((res) => setTimeout(res, 600));
  }
  const url = await store.control('url');
  try {
    await KSU.exec(`su -c 'am start -a android.intent.action.VIEW -d "${url}"'`);
  } catch (err) {
    window.open(url, '_blank');
  }
}

// Log Viewer Logic
const logSearch = ref('');
const logContainer = ref(null);

const filteredLogText = computed(() => {
  if (!store.logs) return '';
  // Strip ALL ANSI escape codes and carriage returns completely
  const cleanLogs = store.logs
    .replace(/\x1B\[[0-9;]*[a-zA-Z]/g, '')
    .replace(/\x1B\][^\x07]*\x07/g, '')
    .replace(/\x1B[()][AB012]/g, '')
    .replace(/\r/g, '');
  if (!logSearch.value.trim()) return cleanLogs.trim();
  
  const q = logSearch.value.toLowerCase();
  const lines = cleanLogs.split('\n');
  return lines.filter((l) => l.toLowerCase().includes(q)).join('\n').trim();
});

function scrollLogBottom() {
  nextTick(() => {
    if (logContainer.value) logContainer.value.scrollTop = logContainer.value.scrollHeight;
  });
}

watch(() => store.logs, scrollLogBottom);
onMounted(scrollLogBottom);
</script>
