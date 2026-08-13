<template>
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/70 backdrop-blur-md p-0 sm:p-4"
        @click.self="$emit('close')"
      >
        <Transition name="slide-up">
          <div
            v-if="show"
            class="w-full max-w-lg bg-surface-container rounded-t-3xl sm:rounded-3xl p-5 shadow-2xl border border-white/10 text-on-surface flex flex-col max-h-[85vh] h-[550px]"
          >
            <!-- Modal Header -->
            <div class="flex items-center justify-between border-b border-white/10 pb-3 mb-3">
              <div class="flex items-center gap-2">
                <span class="text-base">📂</span>
                <h3 class="text-sm font-black text-on-surface">
                  {{ mode === 'directory' ? 'Pilih Folder Tujuan Backup' : 'Pilih File Backup (.tar.gz)' }}
                </h3>
              </div>
              <button
                @click="$emit('close')"
                class="w-8 h-8 rounded-full flex items-center justify-center bg-surface-container-high hover:bg-surface-container-highest text-on-surface-variant transition-colors"
              >
                ✕
              </button>
            </div>

            <!-- Breadcrumb Navigation Bar -->
            <div class="flex items-center justify-between gap-2 mb-3 bg-surface-container-lowest/80 border border-white/5 rounded-xl p-2.5">
              <!-- Up/Back Button -->
              <button
                @click="navigateUp"
                :disabled="currentPath === '/'"
                class="w-7 h-7 rounded-lg bg-surface-container-highest flex items-center justify-center text-xs font-bold text-on-surface disabled:opacity-30 disabled:pointer-events-none hover:bg-primary/20 transition-all shrink-0"
                title="Folder Induk"
              >
                ⬆
              </button>

              <!-- Scrollable Breadcrumbs -->
              <div class="flex-1 min-w-0 overflow-x-auto scrollbar-hidden flex items-center text-xs space-x-1 font-mono">
                <span
                  v-for="(crumb, idx) in breadcrumbs"
                  :key="crumb.path"
                  class="flex items-center shrink-0"
                >
                  <button
                    @click="navigateTo(crumb.path)"
                    class="hover:text-primary transition-colors py-0.5 px-1 rounded hover:bg-white/5"
                    :class="idx === breadcrumbs.length - 1 ? 'font-bold text-primary' : 'text-on-surface-variant'"
                  >
                    {{ crumb.name }}
                  </button>
                  <span v-if="idx < breadcrumbs.length - 1" class="text-on-surface-variant/40 mx-0.5">/</span>
                </span>
              </div>

              <!-- Sort Cycle Button -->
              <button
                @click="cycleSort"
                class="text-[0.65rem] font-bold px-2 py-1 rounded-lg bg-surface-container-highest text-on-surface-variant border border-white/5 shrink-0"
              >
                {{ currentSortLabel }}
              </button>
            </div>

            <!-- Directory Items List -->
            <div class="flex-1 overflow-y-auto scrollbar-hidden space-y-1 pr-1">
              <div v-if="loading" class="text-center py-12 text-xs text-on-surface-variant flex items-center justify-center gap-2">
                <span class="animate-spin">🔄</span> Membaca direktori...
              </div>

              <div v-else-if="items.length === 0" class="text-center py-12 text-xs text-on-surface-variant/60">
                Folder ini kosong
              </div>

              <template v-else>
                <div
                  v-for="item in sortedItems"
                  :key="item.name"
                  @click="handleItemClick(item)"
                  class="flex items-center justify-between p-3 rounded-2xl border transition-all cursor-pointer select-none"
                  :class="getItemClass(item)"
                >
                  <div class="flex items-center gap-3 min-w-0">
                    <span class="text-lg shrink-0">{{ item.isDir ? '📁' : '📦' }}</span>
                    <div class="min-w-0">
                      <div class="text-xs font-bold truncate text-on-surface">{{ item.name }}</div>
                      <div class="text-[0.65rem] text-on-surface-variant/70 font-mono mt-0.5">
                        {{ item.isDir ? 'Folder' : formatSize(item.size) }} · {{ formatDate(item.mtime) }}
                      </div>
                    </div>
                  </div>

                  <span v-if="item.isDir" class="text-xs text-on-surface-variant/40">➔</span>
                  <span v-else-if="selectedFilePath === getFullPath(item.name)" class="text-xs text-emerald-400 font-bold">✓</span>
                </div>
              </template>
            </div>

            <!-- Footer Action Area -->
            <div class="pt-3 border-t border-white/10 mt-3 flex items-center justify-between gap-3">
              <div class="text-xs text-on-surface-variant truncate font-mono">
                <span class="opacity-60">Path:</span> {{ currentPath }}
              </div>

              <div class="flex gap-2 shrink-0">
                <button
                  @click="$emit('close')"
                  class="text-xs font-bold py-2 px-4 rounded-xl bg-surface-container-high text-on-surface hover:bg-surface-container-highest"
                >
                  Batal
                </button>

                <!-- Directory Select Button -->
                <button
                  v-if="mode === 'directory'"
                  @click="confirmDirectorySelection"
                  class="text-xs font-bold py-2 px-4 rounded-xl bg-primary text-on-primary shadow-md hover:brightness-110 active:scale-95 transition-all"
                >
                  Pilih Folder Ini
                </button>

                <!-- File Select Button -->
                <button
                  v-else
                  @click="confirmFileSelection"
                  :disabled="!selectedFilePath"
                  class="text-xs font-bold py-2 px-4 rounded-xl bg-primary text-on-primary shadow-md hover:brightness-110 active:scale-95 transition-all disabled:opacity-40 disabled:pointer-events-none"
                >
                  Pilih File
                </button>
              </div>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import * as KSU from '@/helpers/KernelSU';

const props = defineProps({
  show: { type: Boolean, default: false },
  mode: { type: String, default: 'file' }, // 'file' or 'directory'
  initialPath: { type: String, default: '/sdcard/Download' },
});

const emit = defineEmits(['close', 'select']);

const currentPath = ref('/sdcard/Download');
const items = ref([]);
const loading = ref(false);
const selectedFilePath = ref('');
const sortIndex = ref(0);

const sortOptions = [
  { label: 'A–Z', sort: (a, b) => a.name.localeCompare(b.name) },
  { label: 'Z–A', sort: (a, b) => b.name.localeCompare(a.name) },
  { label: 'Terbaru', sort: (a, b) => b.mtime - a.mtime },
  { label: 'Terlama', sort: (a, b) => a.mtime - b.mtime },
];

const currentSortLabel = computed(() => sortOptions[sortIndex.value].label);

const breadcrumbs = computed(() => {
  const parts = currentPath.value.split('/').filter(Boolean);
  const result = [{ name: 'Storage', path: '/sdcard' }];
  let pathAcc = '';
  for (const part of parts) {
    pathAcc += '/' + part;
    if (pathAcc === '/sdcard' || pathAcc === '/storage/emulated/0') {
      continue;
    }
    result.push({ name: part, path: pathAcc });
  }
  return result;
});

const sortedItems = computed(() => {
  const dirs = items.value.filter((i) => i.isDir).sort(sortOptions[sortIndex.value].sort);
  const files = items.value.filter((i) => !i.isDir).sort(sortOptions[sortIndex.value].sort);
  return [...dirs, ...files];
});

function cycleSort() {
  sortIndex.value = (sortIndex.value + 1) % sortOptions.length;
}

function getFullPath(name) {
  return currentPath.value === '/' ? `/${name}` : `${currentPath.value}/${name}`;
}

function shellQuote(s) {
  return `'${String(s).replaceAll("'", "'\\''")}'`;
}

async function loadDirectory(path) {
  loading.value = true;
  selectedFilePath.value = '';
  try {
    const targetPath = path || '/sdcard/Download';
    const cmd = `cd ${shellQuote(targetPath)} 2>/dev/null && stat -c '%F\t%s\t%Y\t%n' * 2>/dev/null`;
    const res = await KSU.exec(`su -c ${shellQuote(cmd)}`);
    const list = [];
    if (res.stdout) {
      for (const line of res.stdout.split('\n')) {
        if (!line.trim()) continue;
        const parts = line.split('\t');
        if (parts.length < 4) continue;
        const isDir = parts[0] === 'directory';
        const size = parseInt(parts[1], 10) || 0;
        const mtime = parseInt(parts[2], 10) || 0;
        const name = parts.slice(3).join('\t');

        // Filter files if in 'file' mode (show tar.gz or all files)
        if (!isDir && props.mode === 'file' && !name.endsWith('.tar.gz') && !name.endsWith('.gz') && !name.endsWith('.json')) {
          continue;
        }

        list.push({ isDir, size, mtime, name });
      }
    }
    currentPath.value = targetPath;
    items.value = list;
  } catch (err) {
    items.value = [];
  } finally {
    loading.value = false;
  }
}

function navigateTo(path) {
  loadDirectory(path);
}

function navigateUp() {
  if (currentPath.value === '/' || currentPath.value === '') return;
  const parent = currentPath.value.replace(/\/[^/]*$/, '') || '/';
  loadDirectory(parent);
}

function handleItemClick(item) {
  if (item.isDir) {
    navigateTo(getFullPath(item.name));
  } else {
    selectedFilePath.value = getFullPath(item.name);
  }
}

function confirmDirectorySelection() {
  emit('select', currentPath.value);
  emit('close');
}

function confirmFileSelection() {
  if (selectedFilePath.value) {
    emit('select', selectedFilePath.value);
    emit('close');
  }
}

function getItemClass(item) {
  const full = getFullPath(item.name);
  if (selectedFilePath.value === full) {
    return 'bg-emerald-950/60 border-emerald-500/50 text-emerald-200';
  }
  return 'bg-surface-container-highest/50 border-white/5 hover:bg-surface-container-highest hover:border-white/10';
}

function formatSize(b) {
  if (b >= 1048576) return (b / 1048576).toFixed(1) + ' MB';
  if (b >= 1024) return (b / 1024).toFixed(1) + ' KB';
  return b + ' B';
}

function formatDate(sec) {
  if (!sec) return '';
  const d = new Date(sec * 1000);
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

watch(
  () => props.show,
  (val) => {
    if (val) {
      loadDirectory(props.initialPath || '/sdcard/Download');
    }
  }
);
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
}

@media (min-width: 640px) {
  .slide-up-enter-from,
  .slide-up-leave-to {
    transform: scale(0.95) translateY(10px);
    opacity: 0;
  }
}
</style>
