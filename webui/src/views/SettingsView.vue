<template>
  <div class="scrollbar-hidden pb-safe-nav flex-1 min-h-0 overflow-y-scroll h-full">
    <div class="max-w-3xl mx-auto p-5 py-1 space-y-4">

      <!-- Boot Autostart Card -->
      <div class="bg-surface-container border border-outline-variant/30 p-4 rounded-xl text-on-surface">
        <div class="flex items-start justify-between gap-4">
          <div class="flex items-start gap-3">
            <span class="w-5 h-5 shrink-0 text-on-surface-variant mt-0.5"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg></span>
            <div>
              <h3 class="text-sm font-medium">Jalankan Saat Boot</h3>
              <p class="text-xs text-on-surface-variant mt-1">Jalankan launcher background HTTP otomatis saat perangkat Android dinyalakan.</p>
            </div>
          </div>
          <ToggleSwitch
            :model-value="store.isAutostart"
            :disabled="store.busy"
            label="Jalankan saat boot"
            @update:model-value="toggleAutostart"
            class="shrink-0"
          />
        </div>
      </div>

      <!-- Network Port Settings Card -->
      <div class="bg-surface-container border border-outline-variant/30 p-4 rounded-xl text-on-surface">
        <div class="flex items-start justify-between gap-4">
          <div class="flex items-start gap-3">
            <span class="w-5 h-5 shrink-0 text-on-surface-variant mt-0.5"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="2" y1="12" x2="22" y2="12"></line><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path></svg></span>
            <div>
              <h3 class="text-sm font-medium">Port HTTP Launcher</h3>
              <p class="text-xs text-on-surface-variant mt-1">
                Port aktif: <span class="font-mono text-primary font-bold">{{ store.status.PORT }}</span> (listen 127.0.0.1)
              </p>
            </div>
          </div>
          <Ripple
            class="bg-surface-container-high hover:bg-surface-container-highest text-on-surface text-xs font-medium px-4 py-2 rounded-lg shrink-0 cursor-pointer"
            @click="showPortModal = true"
          >
            Ubah
          </Ripple>
        </div>
      </div>

      <!-- Termux Integration Card -->
      <div class="bg-surface-container border border-outline-variant/30 p-4 rounded-xl text-on-surface">
        <div class="flex items-start justify-between gap-4 mb-4">
          <div class="flex items-start gap-3">
            <span class="w-5 h-5 shrink-0 text-on-surface-variant mt-0.5"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"></polyline><line x1="12" y1="19" x2="20" y2="19"></line></svg></span>
            <div>
              <h3 class="text-sm font-medium">Integrasi Termux CLI</h3>
              <p class="text-xs text-on-surface-variant mt-1">
                Pasang wrapper CLI root di $PREFIX/bin Termux
              </p>
            </div>
          </div>
          <span
            class="text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full shrink-0"
            :class="store.status.WRAPPERS === 'ready' ? 'bg-primary/20 text-primary border border-primary/30' : 'bg-error/20 text-error border border-error/30'"
          >
            {{ store.status.WRAPPERS === 'ready' ? 'Ready' : 'Sync' }}
          </span>
        </div>
        <Ripple
          class="w-full bg-primary text-on-primary font-medium text-center text-sm py-3 px-4 rounded-xl cursor-pointer"
          :class="{ 'opacity-50 pointer-events-none': store.busy }"
          @click="store.executeAction('wrappers')"
        >
          Pasang / Sync Wrapper Termux
        </Ripple>
      </div>

      <!-- Port Edit Modal Dialog -->
      <Modal :show="showPortModal" title="Ubah Port HTTP Launcher" @close="showPortModal = false">
        <div class="space-y-4">
          <p class="text-xs text-on-surface-variant">
            Pilih atau ketik nomor port lokal baru (1 - 65535):
          </p>

          <div class="flex flex-wrap gap-2">
            <button
              v-for="p in [18800, 18801, 8080, 9090]"
              :key="p"
              @click="newPortInput = String(p)"
              class="text-xs font-mono font-medium py-1.5 px-3 rounded-lg bg-surface-container-high text-on-surface border border-outline-variant hover:border-primary transition-colors"
            >
              {{ p }}
            </button>
          </div>

          <input
            v-model="newPortInput"
            type="number"
            min="1"
            max="65535"
            class="w-full bg-surface-container-low border border-outline-variant rounded-xl p-3 text-sm font-mono text-on-surface focus:outline-none focus:border-primary"
          />
        </div>
        <template #actions>
          <button
            @click="showPortModal = false"
            class="text-xs font-medium py-2 px-4 rounded-lg bg-surface-container-high text-on-surface"
          >
            Batal
          </button>
          <Ripple
            class="text-xs font-medium py-2 px-4 rounded-lg bg-primary text-on-primary cursor-pointer"
            @click="savePort"
          >
            Simpan
          </Ripple>
        </template>
      </Modal>

    </div>
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
</script>
