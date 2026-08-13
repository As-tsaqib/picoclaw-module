<template>
  <div class="flex flex-col h-full w-full">
    <div class="flex items-center gap-3 p-3 border-b border-surface-container bg-surface-container-low" :style="{ paddingTop: 'var(--window-inset-top, env(safe-area-inset-top, 0px))' }">
      <button @click="router.back()" class="w-10 h-10 rounded-full bg-surface-container hover:bg-surface-container-high flex items-center justify-center text-on-surface">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5"/><path d="m12 19-7-7 7-7"/></svg>
      </button>
      <div class="flex flex-col">
        <span class="text-sm font-semibold">Node-RED Dashboard</span>
        <span class="text-[10px] text-on-surface-variant font-mono">{{ url }}</span>
      </div>
      <button @click="openExternal" class="ml-auto w-10 h-10 rounded-full bg-surface-container hover:bg-surface-container-high flex items-center justify-center text-on-surface" title="Buka di Browser Eksternal">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
      </button>
    </div>
    
    <iframe v-if="url" :src="url" class="flex-1 w-full border-none" sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-modals"></iframe>
    <div v-else class="flex-1 flex items-center justify-center text-on-surface-variant">
      Memuat URL Dashboard...
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import * as KSU from '@/helpers/KernelSU';

const router = useRouter();
const route = useRoute();
const store = usePicoClawStore();
const url = ref('');

onMounted(async () => {
  if (route.query.url) {
    url.value = route.query.url;
  } else {
    url.value = await store.control('url');
  }
});

async function openExternal() {
  if (!url.value) return;
  try {
    await KSU.exec(`su -c 'am start -a android.intent.action.VIEW -d "${url.value}"'`);
  } catch (err) {
    window.open(url.value, '_blank');
  }
}
</script>
