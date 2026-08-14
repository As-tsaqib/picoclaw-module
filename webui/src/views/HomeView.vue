<template>
  <div class="scrollbar-hidden pb-safe-nav flex-1 min-h-0 overflow-y-scroll h-full">
    <div class="max-w-3xl mx-auto p-5 py-1">
      
      <!-- Daemon Status -->
      <Ripple
        @click="toggleLauncher"
        :tabindex="store.busy ? -1 : 0"
        :aria-label="store.isRunning ? 'Hentikan dashboard' : 'Mulai dashboard'"
        :aria-pressed="store.isRunning"
        class="w-full bg-secondary-container border border-outline-variant/30 mb-4 p-4 rounded-xl flex items-center gap-4 text-on-secondary-container text-left cursor-pointer"
        :class="{ 'opacity-50 pointer-events-none': store.busy }"
      >
        <span
          class="w-12 h-12 rounded-full flex items-center justify-center shrink-0 transition-colors duration-200"
          :class="store.isRunning ? 'bg-primary text-on-primary' : 'bg-surface-variant text-on-surface-variant'"
          aria-hidden="true"
        >
          <Transition name="status-icon" mode="out-in">
            <!-- Play icon (saat berhenti) -->
            <svg v-if="!store.isRunning" key="play" class="w-6 h-6 ml-0.5" viewBox="0 0 24 24" fill="currentColor"><polygon points="6 3 20 12 6 21 6 3"></polygon></svg>
            <!-- Stop icon (saat aktif) -->
            <svg v-else key="stop" class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="12" height="14" rx="1"></rect></svg>
          </Transition>
        </span>
        <div class="flex-1 flex flex-col">
          <span class="text-lg font-semibold">{{ store.isRunning ? 'Dashboard Aktif' : 'Dashboard Berhenti' }}</span>
          <span class="text-xs pt-1 block opacity-80">{{ store.isRunning ? `PID ${store.status.PID} · Port ${store.status.PORT}` : 'Ketuk tombol untuk memulai.' }}</span>
        </div>
      </Ripple>

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
        <h3 class="text-sm font-medium text-center mb-3">Manajemen Konfigurasi</h3>
        <div class="border-t border-outline-variant/40 mb-3" role="separator" aria-hidden="true"></div>
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

      <!-- Health & Diagnostics -->
      <div class="bg-surface-container border border-outline-variant/30 mb-4 p-4 rounded-xl text-on-surface">
        <div class="flex flex-wrap items-center justify-between gap-3 mb-3">
          <div>
            <h3 class="text-sm font-medium">Health &amp; Diagnostics</h3>
            <p class="text-xs text-on-surface-variant mt-1">Status launcher dan pemeriksaan runtime tanpa credential.</p>
          </div>
          <span
            class="text-[10px] font-bold uppercase tracking-wide px-2 py-1 rounded-full border"
            :class="diagnosticStatusClass(store.status.HTTP_STATUS)"
          >
            HTTP {{ store.status.HTTP_STATUS || 'down' }}
          </span>
        </div>
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-2 text-xs">
          <div class="diagnostic-cell"><span>PID</span><strong>{{ store.status.PID || '—' }}</strong></div>
          <div class="diagnostic-cell"><span>Uptime</span><strong>{{ formatUptime(store.status.UPTIME_SECONDS) }}</strong></div>
          <div class="diagnostic-cell"><span>Last start</span><strong>{{ formatEpoch(store.status.LAST_START_TIME_EPOCH || store.status.START_TIME_EPOCH) }}</strong></div>
          <div class="diagnostic-cell"><span>Watchdog</span><strong :class="diagnosticTextClass(store.status.WATCHDOG_STATUS === 'enabled')">{{ store.status.WATCHDOG_STATUS || '—' }}</strong></div>
          <div class="diagnostic-cell"><span>Binary</span><strong :class="diagnosticTextClass(store.status.BINARY_STATUS === 'ok')">{{ store.status.BINARY_STATUS || '—' }}</strong></div>
          <div class="diagnostic-cell"><span>Permission</span><strong :class="diagnosticTextClass(store.status.PERMISSION_STATUS === 'ok')">{{ store.status.PERMISSION_STATUS || '—' }}</strong></div>
          <div class="diagnostic-cell"><span>Config</span><strong :class="diagnosticTextClass(store.status.CONFIG_STATUS === 'ok')">{{ store.status.CONFIG_STATUS || '—' }}</strong></div>
          <div class="diagnostic-cell"><span>Listener</span><strong :class="diagnosticTextClass(store.status.LISTENER_STATUS === 'ok')">{{ store.status.LISTENER_STATUS || '—' }}</strong></div>
          <div class="diagnostic-cell"><span>Wrapper</span><strong :class="diagnosticTextClass(store.status.WRAPPER_STATUS === 'ready')">{{ store.status.WRAPPER_STATUS || '—' }}</strong></div>
        </div>
        <p v-if="store.status.LAST_RESTART_REASON && store.status.LAST_RESTART_REASON !== 'none'" class="text-[11px] text-on-surface-variant mt-3">
          Restart terakhir: {{ store.status.LAST_RESTART_REASON }} · {{ formatEpoch(store.status.LAST_RESTART_TIME_EPOCH) }}
        </p>
        <Ripple
          class="mt-3 w-full sm:w-auto bg-surface-container-high hover:bg-surface-container-highest text-on-surface text-xs font-medium px-4 py-2 rounded-lg cursor-pointer text-center"
          @click="copyDiagnosticReport"
        >
          Salin laporan diagnostik
        </Ripple>
      </div>


      <!-- Logs -->
      <div class="service-logs-card bg-surface-container border border-outline-variant/30 mb-4 p-4 rounded-xl flex flex-col overflow-hidden text-on-surface">
        <div class="flex flex-wrap gap-2 justify-between items-center mb-3">
          <h3 class="text-sm font-medium">Service Logs</h3>
          <div class="flex flex-wrap items-center justify-end gap-2">
            <select v-model="store.logLines" @change="store.refresh()" class="bg-surface-container-high border-none text-xs rounded-md px-2 py-1 outline-none text-on-surface">
              <option value="50">50 Baris</option>
              <option value="100">100 Baris</option>
              <option value="300">300 Baris</option>
            </select>
            <select v-model="logLevel" class="bg-surface-container-high border-none text-xs rounded-md px-2 py-1 outline-none text-on-surface" aria-label="Filter level log">
              <option value="all">Semua level</option>
              <option value="error">Error</option>
              <option value="warning">Warning</option>
              <option value="info">Info</option>
            </select>
            <Ripple @click="toggleLogTail" class="cursor-pointer bg-surface-container-high text-on-surface px-3 py-1 rounded-md text-xs font-medium">
              {{ logPaused ? 'Live tail' : 'Pause' }}
            </Ripple>
            <Ripple @click="downloadLogs" class="cursor-pointer bg-surface-container-high text-on-surface px-3 py-1 rounded-md text-xs font-medium">
              Export
            </Ripple>
            <Ripple @click="confirmClearLogs" class="cursor-pointer bg-error/20 text-error px-3 py-1 rounded-md text-xs font-medium">
              Clear
            </Ripple>
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-2 mb-3">
          <input
            v-model="logSearch"
            type="text"
            placeholder="Filter logs..."
            class="flex-1 min-w-[10rem] bg-surface-container-high border border-outline-variant/30 text-xs px-3 py-2 rounded-lg outline-none focus:border-primary text-on-surface"
          />
          <label class="log-option"><input v-model="wrapText" type="checkbox" /> Wrap text</label>
          <label class="log-option"><input v-model="rawLog" type="checkbox" /> Raw log</label>
        </div>
        <div class="flex-1 min-h-0 overflow-y-auto bg-[#1e1e1e] border border-outline-variant/30 rounded-lg text-[#d4d4d4]" :class="{ 'overflow-x-auto': rawLog }" ref="logContainer">
          <div v-if="filteredLogEntries.length" class="log-output p-3" :class="{ 'log-output-wrap': wrapText, 'log-output-raw': rawLog }">
            <div v-for="entry in filteredLogEntries" :key="entry.key" class="log-entry" :class="entry.levelClass">
              <span class="log-line-number">{{ entry.number }}</span><span v-if="entry.timestamp" class="log-timestamp">{{ entry.timestamp }}</span><span class="log-entry-text">{{ entry.text }}</span>
            </div>
          </div>
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
import { usePicoClawStore } from '@/stores/PicoClawStore';
import * as KSU from '@/helpers/KernelSU';
import FilePickerModal from '@/components/ui/FilePickerModal.vue';
import Ripple from '@/components/ui/Ripple.vue';

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

async function toggleLauncher() {
  if (store.busy) return;

  try {
    await store.executeAction(store.isRunning ? 'stop' : 'start');
  } catch {
    // The store exposes the action error to the user.
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

// Health & diagnostics and log viewer helpers deliberately use whitelisted
// status fields. The report never includes config contents, credentials, or
// raw logs.
const diagnosticFields = [
  ['HTTP status', 'HTTP_STATUS'], ['PID', 'PID'], ['Uptime seconds', 'UPTIME_SECONDS'],
  ['Last start (epoch)', 'LAST_START_TIME_EPOCH'], ['Watchdog', 'WATCHDOG_STATUS'],
  ['Last restart reason', 'LAST_RESTART_REASON'], ['Last restart (epoch)', 'LAST_RESTART_TIME_EPOCH'],
  ['Binary', 'BINARY_STATUS'], ['Permission', 'PERMISSION_STATUS'], ['Config', 'CONFIG_STATUS'],
  ['Listener', 'LISTENER_STATUS'], ['Wrapper', 'WRAPPER_STATUS'], ['Port', 'PORT'],
];

function diagnosticStatusClass(value) {
  return value === 'ok' ? 'bg-primary/20 text-primary border-primary/30' : 'bg-error/20 text-error border-error/30';
}

function diagnosticTextClass(ok) {
  return ok ? 'text-primary' : 'text-error';
}

function formatUptime(value) {
  const seconds = Number(value);
  if (!Number.isFinite(seconds) || seconds < 1) return '—';
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);
  return `${days ? `${days}d ` : ''}${hours ? `${hours}h ` : ''}${minutes ? `${minutes}m ` : ''}${secs}s`.trim();
}

function formatEpoch(value) {
  const epoch = Number(value);
  if (!Number.isFinite(epoch) || epoch <= 0) return '—';
  try { return new Date(epoch * 1000).toLocaleString(); } catch { return '—'; }
}

async function copyDiagnosticReport() {
  const report = diagnosticFields
    .map(([label, key]) => `${label}: ${store.status[key] || '—'}`)
    .join('\n');
  try {
    await navigator.clipboard.writeText(`PicoClaw diagnostics\n${report}`);
    store.setToast?.('Laporan diagnostik disalin');
    if (!store.setToast) store.toastMessage = 'Laporan diagnostik disalin';
  } catch {
    store.toastMessage = 'Clipboard tidak tersedia';
    KSU.toast('Clipboard tidak tersedia');
  }
}

const logSearch = ref('');
const logLevel = ref('all');
const logPaused = ref(false);
const pausedLogs = ref('');
const wrapText = ref(true);
const rawLog = ref(false);
const logContainer = ref(null);

function redactLogText(value) {
  return String(value || '')
    .replace(/(authorization\s*:\s*bearer\s+)[^\s]+/gi, '$1[REDACTED]')
    .replace(/(bearer\s+)[A-Za-z0-9._~+\/-]{8,}/gi, '$1[REDACTED]')
    .replace(/((?:api[_-]?key|token|password|passwd|secret|cookie)\s*[:=]\s*)[^\s]+/gi, '$1[REDACTED]')
    .replace(/\b(?:sk|gh[pousr])_[A-Za-z0-9_-]{8,}\b/g, '[REDACTED]');
}

function cleanLogLine(value) {
  const redacted = redactLogText(value).replace(/\r/g, '');
  if (rawLog.value) return redacted;
  return redacted
    .replace(/\x1B\[[0-9;]*[a-zA-Z]/g, '')
    .replace(/\x1B\][^\x07]*\x07/g, '')
    .replace(/\x1B[()][AB012]/g, '');
}

function classifyLogLevel(line) {
  const lower = line.toLowerCase();
  if (/\b(error|err|fatal|panic|gagal|failed|failure)\b/.test(lower)) return 'error';
  if (/\b(warn|warning|wrn|peringatan)\b/.test(lower)) return 'warning';
  return 'info';
}

function extractTimestamp(line) {
  const match = line.match(/^\s*(\[?\d{4}-\d{2}-\d{2}[ t]\d{2}:\d{2}:\d{2}(?:\.\d+)?\]?|\[?\d{2}:\d{2}:\d{2}(?:\.\d+)?\]?)/i);
  return match ? match[1] : '';
}

const displayedLogs = computed(() => logPaused.value ? pausedLogs.value : store.logs);
const filteredLogEntries = computed(() => {
  const query = logSearch.value.trim().toLowerCase();
  return String(displayedLogs.value || '').split('\n')
    .map((line, index) => ({ line: cleanLogLine(line), number: index + 1 }))
    .filter(({ line }) => line.length > 0)
    .map(({ line, number }) => {
      const level = classifyLogLevel(line);
      const timestamp = extractTimestamp(line);
      return {
        key: `${number}:${line}`,
        number,
        timestamp,
        text: rawLog.value || !timestamp ? line : line.slice(timestamp.length).trimStart(),
        level,
        levelClass: `log-${level}`,
      };
    })
    .filter((entry) => (logLevel.value === 'all' || entry.level === logLevel.value) &&
      (!query || entry.text.toLowerCase().includes(query)));
});

function toggleLogTail() {
  if (!logPaused.value) {
    pausedLogs.value = store.logs;
    logPaused.value = true;
  } else {
    logPaused.value = false;
    scrollLogBottom();
  }
}

function confirmClearLogs() {
  if (window.confirm('Bersihkan service log? Tindakan ini tidak dapat dibatalkan.')) {
    store.executeAction('clear-logs');
  }
}

function downloadLogs() {
  const content = filteredLogEntries.value.map((entry) => `${String(entry.number).padStart(5, ' ')} ${entry.text}`).join('\n');
  const blob = new Blob([`${content}\n`], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = `picoclaw-log-${new Date().toISOString().replace(/[:.]/g, '-')}.txt`;
  anchor.click();
  URL.revokeObjectURL(url);
}

function scrollLogBottom() {
  nextTick(() => {
    if (logContainer.value) logContainer.value.scrollTop = logContainer.value.scrollHeight;
  });
}

watch(() => store.logs, () => {
  if (!logPaused.value) scrollLogBottom();
});
onMounted(scrollLogBottom);
</script>
