<template>
  <div class="space-y-4">
    <!-- Boot Autostart Card -->
    <div class="glass-card rounded-3xl p-5 flex items-center justify-between">
      <div class="space-y-1">
        <div class="flex items-center gap-2">
          <span class="text-sm">⚙️</span>
          <h3 class="text-sm font-black text-on-surface">Jalankan Saat Boot</h3>
        </div>
        <p class="text-xs text-on-surface-variant font-medium">
          Jalankan launcher background HTTP otomatis saat perangkat Android dinyalakan.
        </p>
      </div>
      <ToggleSwitch
        :model-value="store.isAutostart"
        :disabled="store.busy"
        @update:model-value="toggleAutostart"
      />
    </div>

    <!-- Network Port Settings Card -->
    <div class="glass-card rounded-3xl p-5 flex items-center justify-between">
      <div class="space-y-1">
        <div class="flex items-center gap-2">
          <span class="text-sm">🌐</span>
          <h3 class="text-sm font-black text-on-surface">Port HTTP Launcher</h3>
        </div>
        <p class="text-xs text-on-surface-variant font-medium">
          Port aktif: <span class="font-mono text-primary font-bold">{{ store.status.PORT }}</span> (listen 127.0.0.1)
        </p>
      </div>
      <Ripple
        class="bg-surface-container-highest/80 hover:bg-surface-container-highest text-on-surface text-xs font-bold px-4 py-2.5 rounded-xl cursor-pointer border border-white/5 active:scale-95 transition-all"
        @click="showPortModal = true"
      >
        Ubah Port
      </Ripple>
    </div>

    <!-- Backup & Restore Card -->
    <div class="glass-card rounded-3xl p-5 space-y-3">
      <div class="flex items-center gap-2">
        <span class="text-sm">💾</span>
        <div>
          <h3 class="text-sm font-black text-on-surface">Backup & Restore Config</h3>
          <p class="text-xs text-on-surface-variant font-medium mt-0.5">
            Cadangkan config.json, settings.conf, dan workspace ke memori /sdcard/Download
          </p>
        </div>
      </div>
      <div class="grid grid-cols-2 gap-2">
        <Ripple
          class="bg-surface-container-highest/80 hover:bg-surface-container-highest text-on-surface text-center text-xs font-bold py-2.5 px-3 rounded-xl cursor-pointer border border-white/5 active:scale-95 transition-all"
          :class="{ 'opacity-40 pointer-events-none': store.busy }"
          @click="store.executeAction('backup')"
        >
          📁 Backup Config
        </Ripple>
        <Ripple
          class="bg-surface-container-highest/80 hover:bg-surface-container-highest text-on-surface text-center text-xs font-bold py-2.5 px-3 rounded-xl cursor-pointer border border-white/5 active:scale-95 transition-all"
          :class="{ 'opacity-40 pointer-events-none': store.busy }"
          @click="triggerRestore"
        >
          📥 Restore Config
        </Ripple>
      </div>
    </div>

    <!-- Termux Integration Card -->
    <div class="glass-card rounded-3xl p-5 space-y-3">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="text-sm">⚡</span>
          <div>
            <h3 class="text-sm font-black text-on-surface">Integrasi Termux CLI</h3>
            <p class="text-xs text-on-surface-variant font-medium mt-0.5">
              Pasang 17 wrapper CLI root di $PREFIX/bin Termux
            </p>
          </div>
        </div>
        <span
          class="text-[0.65rem] font-extrabold uppercase tracking-wider px-3 py-1 rounded-full border"
          :class="store.status.WRAPPERS === 'ready' ? 'bg-emerald-950/80 text-emerald-300 border-emerald-500/40' : 'bg-amber-950/80 text-amber-300 border-amber-500/40'"
        >
          {{ store.status.WRAPPERS === 'ready' ? 'READY' : 'SYNC' }}
        </span>
      </div>
      <Ripple
        class="w-full bg-gradient-to-r from-primary to-indigo-600 text-on-primary font-extrabold text-center text-xs py-3 px-4 rounded-xl cursor-pointer shadow-md active:scale-95 transition-all"
        :class="{ 'opacity-40 pointer-events-none': store.busy }"
        @click="store.executeAction('wrappers')"
      >
        Pasang / Sync Wrapper Termux
      </Ripple>
    </div>

    <!-- Port Edit Modal Dialog -->
    <Modal :show="showPortModal" title="Ubah Port HTTP Launcher" @close="showPortModal = false">
      <div class="space-y-3">
        <p class="text-xs text-on-surface-variant">
          Pilih atau ketik nomor port lokal baru (1 - 65535):
        </p>

        <!-- Port Presets -->
        <div class="flex gap-2">
          <button
            v-for="p in [18800, 18801, 8080, 9090]"
            :key="p"
            @click="newPortInput = String(p)"
            class="text-xs font-mono font-bold py-1.5 px-3 rounded-lg bg-surface-container-highest text-on-surface border border-white/5 hover:border-primary"
          >
            {{ p }}
          </button>
        </div>

        <input
          v-model="newPortInput"
          type="number"
          min="1"
          max="65535"
          class="w-full bg-surface-container-lowest border border-white/10 rounded-2xl p-3.5 text-sm font-mono text-on-surface focus:outline-none focus:border-primary"
        />
      </div>
      <template #actions>
        <button
          @click="showPortModal = false"
          class="text-xs font-bold py-2.5 px-4 rounded-xl bg-surface-container-highest text-on-surface"
        >
          Batal
        </button>
        <Ripple
          class="text-xs font-bold py-2.5 px-5 rounded-xl bg-primary text-on-primary cursor-pointer shadow-md"
          @click="savePort"
        >
          Simpan & Restart
        </Ripple>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import ToggleSwitch from '@/components/ui/ToggleSwitch.vue';
import Modal from '@/components/ui/Modal.vue';
import Ripple from '@/components/ui/Ripple.vue';

const store = usePicoClawStore();
const showPortModal = ref(false);
const newPortInput = ref(store.status.PORT || '18800');

function toggleAutostart(val) {
  store.executeAction('autostart', val);
}

async function savePort() {
  const p = parseInt(newPortInput.value, 10);
  if (isNaN(p) || p < 1 || p > 65535) {
    store.errorMessage = 'Port tidak valid (1-65535).';
    return;
  }
  showPortModal.value = false;
  await store.executeAction('port', String(p));
}

function triggerRestore() {
  const path = window.prompt('Masukkan path file backup .tar.gz untuk di-restore:', '/sdcard/Download/picoclaw-backup-latest.tar.gz');
  if (path && path.trim()) {
    store.executeAction('restore', path.trim());
  }
}
</script>
