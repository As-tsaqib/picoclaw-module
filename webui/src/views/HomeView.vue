<template>
  <div class="scrollbar-hidden pb-safe-nav flex-1 min-h-0 overflow-y-scroll h-full">
    <div class="max-w-3xl mx-auto p-5 py-1">
      
      <!-- Daemon Status -->
      <div class="bg-secondary-container mb-4 p-4 rounded-xl flex flex-col justify-between text-on-secondary-container">
        <div class="flex items-center gap-4">
          <div class="w-12 h-12 rounded-full flex items-center justify-center shrink-0" :class="store.isRunning ? 'bg-primary text-on-primary' : 'bg-surface-variant text-on-surface-variant'">
            <span class="text-2xl">{{ store.isRunning ? '🚀' : '⏸' }}</span>
          </div>
          <div class="flex-1 flex flex-col">
            <span class="text-lg font-semibold">{{ store.isRunning ? 'Dashboard Aktif' : 'Dashboard Berhenti' }}</span>
            <span class="text-xs pt-1 block opacity-80">{{ store.isRunning ? `PID ${store.status.PID} · Port ${store.status.PORT}` : 'Layanan tidak berjalan.' }}</span>
          </div>
        </div>
        
        <div class="mt-4 grid grid-cols-3 gap-2">
          <Ripple
            class="bg-surface-container hover:bg-surface-container-high text-on-surface text-center py-2 px-3 rounded-lg font-medium cursor-pointer text-xs flex items-center justify-center gap-1.5"
            :class="{ 'opacity-50 pointer-events-none': store.isRunning || store.busy }"
            @click="store.executeAction('start')"
          >
            Start
          </Ripple>
          <Ripple
            class="bg-surface-container hover:bg-surface-container-high text-on-surface text-center py-2 px-3 rounded-lg font-medium cursor-pointer text-xs flex items-center justify-center gap-1.5"
            :class="{ 'opacity-50 pointer-events-none': !store.isRunning || store.busy }"
            @click="store.executeAction('stop')"
          >
            Stop
          </Ripple>
          <Ripple
            class="bg-surface-container hover:bg-surface-container-high text-on-surface text-center py-2 px-3 rounded-lg font-medium cursor-pointer text-xs flex items-center justify-center gap-1.5"
            :class="{ 'opacity-50 pointer-events-none': store.busy }"
            @click="store.executeAction('restart')"
          >
            Restart
          </Ripple>
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
        <span class="text-xl">↗</span>
      </Ripple>

      <!-- Backup & Restore -->
      <div class="bg-surface-container mb-4 p-4 rounded-xl text-on-surface">
        <h3 class="text-sm font-medium mb-3">Manajemen Konfigurasi</h3>
        <div class="grid grid-cols-2 gap-3">
          <Ripple
            @click="openBackupPicker"
            class="cursor-pointer bg-surface-container-high hover:bg-surface-container-highest p-3 rounded-lg flex flex-col gap-1 items-center justify-center"
            :class="{ 'opacity-50 pointer-events-none': store.busy }"
          >
            <span class="text-xl">📁</span>
            <span class="text-xs font-medium">Backup</span>
          </Ripple>
          <Ripple
            @click="openRestorePicker"
            class="cursor-pointer bg-surface-container-high hover:bg-surface-container-highest p-3 rounded-lg flex flex-col gap-1 items-center justify-center"
            :class="{ 'opacity-50 pointer-events-none': store.busy }"
          >
            <span class="text-xl">📥</span>
            <span class="text-xs font-medium">Restore</span>
          </Ripple>
        </div>
      </div>

      <!-- Info Card -->
      <div class="bg-surface-container mb-4 p-4 rounded-xl text-on-surface">
        <div class="py-2 flex justify-between items-center border-b border-outline-variant/30 last:border-0">
          <h3 class="text-sm font-medium">Versi Modul</h3>
          <span class="text-xs text-on-surface-variant font-mono">{{ store.status.VERSION || '—' }}</span>
        </div>
        <div class="py-2 flex justify-between items-center border-b border-outline-variant/30 last:border-0">
          <h3 class="text-sm font-medium">Upstream Tag</h3>
          <span class="text-xs text-on-surface-variant font-mono">{{ store.status.UPSTREAM || '—' }}</span>
        </div>
        <div class="py-2 flex justify-between items-center border-b border-outline-variant/30 last:border-0">
          <h3 class="text-sm font-medium">Log File</h3>
          <span class="text-[10px] text-on-surface-variant font-mono truncate max-w-[150px]">{{ store.status.LOG || '—' }}</span>
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
import { ref } from 'vue';
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
</script>
