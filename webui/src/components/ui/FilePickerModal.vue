<template>
  <Teleport to="body">
    <div v-if="show" class="fm" @click.self="$emit('close')">
      <div class="fm-box">
        <div class="fm-bar">
          <button class="icon-btn" @click="navigateUp" :disabled="currentPath === '/'" title="Back">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5"/><path d="m12 19-7-7 7-7"/></svg>
          </button>
          
          <div class="fm-crumb">
            <span
              v-for="(crumb, idx) in breadcrumbs"
              :key="crumb.path"
              class="fm-seg-wrap"
            >
              <span 
                class="fm-seg"
                @click="navigateTo(crumb.path)"
              >{{ crumb.name }}</span>
              <span v-if="idx < breadcrumbs.length - 1" class="fm-sep">/</span>
            </span>
          </div>
          
          <button class="icon-btn" id="fmSort" @click="cycleSort">
            <span>{{ currentSortLabel }}</span>
          </button>
        </div>

        <div class="fm-list" :class="{ switching: loading }">
          <div v-if="items.length === 0 && !loading" class="fm-empty">
            Empty folder
          </div>
          
          <div
            v-for="item in sortedItems"
            :key="item.name"
            class="fm-item"
            :class="{ pick: selectedFilePath === getFullPath(item.name) }"
            @click="handleItemClick(item)"
          >
            <div class="fm-ic" :class="{ dir: item.isDir }">
              <svg v-if="item.isDir" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/></svg>
              <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
            </div>
            <div class="fm-info">
              <div class="fm-nm">{{ item.name }}</div>
              <div class="fm-sub">{{ item.isDir ? 'Folder' : formatSize(item.size) }} · {{ formatDate(item.mtime) }}</div>
            </div>
            <div v-if="selectedFilePath === getFullPath(item.name) && !item.isDir" class="fm-ic dir">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            </div>
          </div>
        </div>

        <div class="fm-foot">
          <button class="fm-cancel ghosttext" @click="$emit('close')">Cancel</button>
          
          <button 
            v-if="mode === 'directory'"
            class="fm-cancel apply-btn"
            @click="confirmDirectorySelection"
          >Select Folder</button>
          
          <button 
            v-else
            class="fm-cancel apply-btn"
            :disabled="!selectedFilePath"
            @click="confirmFileSelection"
          >Select File</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import * as KSU from '@/helpers/KernelSU';

const props = defineProps({
  show: { type: Boolean, default: false },
  mode: { type: String, default: 'file' },
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
  { label: 'Newest', sort: (a, b) => b.mtime - a.mtime },
  { label: 'Oldest', sort: (a, b) => a.mtime - b.mtime },
];
const currentSortLabel = computed(() => sortOptions[sortIndex.value].label);

const breadcrumbs = computed(() => {
  const parts = currentPath.value.split('/').filter(Boolean);
  const result = [{ name: 'Storage', path: '/sdcard' }];
  let pathAcc = '';
  for (const part of parts) {
    pathAcc += '/' + part;
    if (pathAcc === '/sdcard' || pathAcc === '/storage/emulated/0') continue;
    result.push({ name: part, path: pathAcc });
  }
  return result;
});

const sortedItems = computed(() => {
  const dirs = items.value.filter((i) => i.isDir).sort(sortOptions[sortIndex.value].sort);
  const files = items.value.filter((i) => !i.isDir).sort(sortOptions[sortIndex.value].sort);
  return [...dirs, ...files];
});

function cycleSort() { sortIndex.value = (sortIndex.value + 1) % sortOptions.length; }

function getFullPath(name) {
  return currentPath.value === '/' ? `/${name}` : `${currentPath.value}/${name}`;
}

function shellQuote(s) { return `'${String(s).replaceAll("'", "'\\''")}'`; }

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
        
        if (!isDir && props.mode === 'file' && !name.endsWith('.tar.gz') && !name.endsWith('.gz') && !name.endsWith('.json')) {
          continue; // Filter files
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

function navigateTo(path) { loadDirectory(path); }
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

watch(() => props.show, (val) => {
  if (val) loadDirectory(props.initialPath || '/sdcard/Download');
});
</script>

<style scoped>
.fm {
  position: fixed; inset: 0; z-index: 50; background: rgba(0,0,0,.55);
  display: flex; align-items: center; justify-content: center; padding: 16px;
  animation: fmfade .2s ease both;
}
@keyframes fmfade { from { opacity: 0 } to { opacity: 1 } }

.fm-box {
  background: var(--color-surface-container);
  width: 100%; max-width: 460px; height: 80vh; max-height: 660px;
  border-radius: 26px; display: flex; flex-direction: column; overflow: hidden;
  box-shadow: 0 12px 32px rgba(0,0,0,.45), 0 2px 8px rgba(0,0,0,.3);
  animation: fmpop .3s cubic-bezier(.34,1.28,.64,1) both;
}
@keyframes fmpop { from { opacity: 0; transform: scale(.93) } to { opacity: 1; transform: none } }

.fm-bar { display: flex; align-items: center; gap: 6px; padding: 14px 12px 10px; }

.fm-crumb {
  flex: 1; min-width: 0; overflow-x: auto; white-space: nowrap; font-size: 13.5px;
  scrollbar-width: none; -ms-overflow-style: none; padding: 2px 2px;
}
.fm-crumb::-webkit-scrollbar { display: none; }
.fm-seg-wrap { display: inline-block; }
.fm-seg { cursor: pointer; color: var(--color-on-surface); font-weight: 500; }
.fm-seg-wrap:last-child .fm-seg { color: var(--color-on-surface-variant); cursor: default; }
.fm-sep { color: var(--color-on-surface-variant); padding: 0 5px; }

#fmSort { width: auto; padding: 0 12px; height: 34px; font-size: 12px; font-weight: 600; flex-shrink: 0; }

.fm-list {
  flex: 1; overflow-y: auto; padding: 6px 8px; -webkit-overflow-scrolling: touch;
  transition: transform .16s ease, opacity .16s ease;
  will-change: transform, opacity;
}
.fm-list.switching { transform: scale(.97); opacity: 0; }

.fm-item {
  display: flex; align-items: center; gap: 12px; padding: 11px 12px; border-radius: 13px;
  cursor: pointer; transition: background .12s; color: var(--color-on-surface);
}
.fm-item:active { background: color-mix(in srgb, var(--color-on-surface-variant) 15%, transparent); }
.fm-item.pick { background: color-mix(in srgb, var(--color-primary) 15%, transparent); }

.fm-ic { width: 26px; height: 26px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; color: var(--color-on-surface-variant); }
.fm-ic svg { width: 21px; height: 21px; display: block; }
.fm-ic.dir { color: var(--color-primary); }

.fm-info { flex: 1; min-width: 0; }
.fm-nm { font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-weight: 500; }
.fm-sub { font-size: 11px; color: var(--color-on-surface-variant); margin-top: 1px; font-variant-numeric: tabular-nums; }
.fm-empty { text-align: center; color: var(--color-on-surface-variant); font-size: 13px; padding: 36px 16px; }

.fm-foot { display: flex; justify-content: flex-end; gap: 6px; padding: 8px 12px 12px; border-top: 1px solid var(--color-outline-variant); }
.fm-cancel {
  background: transparent; border: 0; color: var(--color-primary); cursor: pointer;
  font: 600 14px/1 inherit; font-family: inherit; padding: 9px 16px; border-radius: 11px;
  transition: background .14s, transform .12s, filter .15s;
}
.fm-cancel:active { background: color-mix(in srgb, var(--color-primary) 14%, transparent); }
.fm-cancel.ghosttext { color: var(--color-on-surface-variant); }
.fm-cancel.apply-btn { background: var(--color-primary); color: var(--color-background); border-radius: 10px; font-weight: 600; }
.fm-cancel.apply-btn:hover { filter: brightness(1.06); }
.fm-cancel.apply-btn:active { transform: scale(.96); }
.fm-cancel.apply-btn[disabled] { opacity: .55; pointer-events: none; }

.icon-btn {
  width: 34px; height: 34px; flex-shrink: 0; border: 0; border-radius: 9px;
  background: color-mix(in srgb, var(--color-on-surface-variant) 10%, transparent);
  color: var(--color-on-surface-variant); cursor: pointer; padding: 0;
  display: flex; align-items: center; justify-content: center;
  transition: background .15s, color .15s, transform .12s;
}
.icon-btn:hover { color: var(--color-on-surface); }
.icon-btn:active { transform: scale(.92); }
.icon-btn svg { width: 17px; height: 17px; display: block; }
.icon-btn[disabled] { opacity: 0.4; pointer-events: none; }
</style>
