<template>
  <div class="overview">

    <!-- Status + Controls -->
    <section class="card card-status">
      <div class="status-row">
        <div class="status-indicator" :class="store.isRunning ? 'ind-on' : 'ind-off'"></div>
        <div class="status-text">
          <strong>{{ store.isRunning ? 'Launcher running' : 'Launcher stopped' }}</strong>
          <span v-if="store.isRunning" class="status-meta">
            PID {{ store.status.PID }} · :{{ store.status.PORT }}
          </span>
          <span v-else class="status-meta">Press Start to launch the service</span>
        </div>
      </div>

      <div class="controls">
        <button class="btn btn-primary" @click="openDashboard">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
          Open Dashboard
        </button>
        <div class="controls-row">
          <button
            class="btn btn-sm"
            :disabled="store.isRunning || store.busy"
            @click="store.executeAction('start')"
          >
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"/></svg>
            Start
          </button>
          <button
            class="btn btn-sm"
            :disabled="!store.isRunning || store.busy"
            @click="store.executeAction('stop')"
          >
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><rect x="4" y="4" width="16" height="16" rx="2"/></svg>
            Stop
          </button>
          <button
            class="btn btn-sm"
            :disabled="store.busy"
            @click="store.executeAction('restart')"
          >
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 2v6h-6"/><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M3 22v-6h6"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/></svg>
            Restart
          </button>
        </div>
      </div>
    </section>

    <!-- Info Grid -->
    <section class="info-grid">
      <div class="info-cell">
        <span class="info-label">Module Version</span>
        <span class="info-value">{{ store.status.VERSION || '—' }}</span>
      </div>
      <div class="info-cell info-cell-action">
        <span class="info-label">Termux Wrappers</span>
        <div class="info-value-row">
          <span class="info-value" :class="store.status.WRAPPERS === 'ready' ? 'val-ok' : 'val-warn'">
            {{ wrapperLabel(store.status.WRAPPERS) }}
          </span>
          <button
            class="btn-icon-sm"
            :disabled="store.busy"
            @click="store.executeAction('wrappers')"
            title="Sync wrappers"
          >
            <svg :class="{ spinning: store.busy }" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 2v6h-6"/><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M3 22v-6h6"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/></svg>
          </button>
        </div>
      </div>
    </section>

    <!-- Settings -->
    <section class="card">
      <h2 class="section-title">Settings</h2>

      <div class="setting-row">
        <div>
          <div class="setting-name">Autostart on boot</div>
          <div class="setting-desc">Start the launcher automatically when the device boots</div>
        </div>
        <label class="toggle">
          <input
            type="checkbox"
            :checked="store.isAutostart"
            :disabled="store.busy"
            @change="store.executeAction('autostart', $event.target.checked)"
          />
          <span class="toggle-track"></span>
        </label>
      </div>

      <div class="setting-row">
        <div>
          <div class="setting-name">HTTP Port</div>
          <div class="setting-desc">Listening on 127.0.0.1:<code>{{ store.status.PORT }}</code></div>
        </div>
        <button class="btn btn-sm" @click="showPortModal = true">Change</button>
      </div>

      <div class="setting-row">
        <div>
          <div class="setting-name">Backup &amp; Restore</div>
          <div class="setting-desc">Save config, settings, and workspace</div>
        </div>
        <div class="btn-pair">
          <button class="btn btn-sm" :disabled="store.busy" @click="store.executeAction('backup')">Backup</button>
          <button class="btn btn-sm" :disabled="store.busy" @click="triggerRestore">Restore</button>
        </div>
      </div>
    </section>

    <!-- Paths -->
    <section class="card">
      <h2 class="section-title">Paths</h2>
      <div class="path-row" v-for="p in paths" :key="p.label">
        <div>
          <div class="setting-name">{{ p.label }}</div>
          <code class="path-code">{{ p.value }}</code>
        </div>
        <button class="btn-link" @click="copyText(p.value)" title="Copy">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
        </button>
      </div>
    </section>

    <!-- Logs -->
    <section class="card">
      <div class="log-header">
        <h2 class="section-title">Service Logs</h2>
        <div class="log-controls">
          <select v-model="store.logLines" @change="store.refresh()" class="log-select">
            <option value="50">50</option>
            <option value="80">80</option>
            <option value="150">150</option>
            <option value="300">300</option>
          </select>
          <button class="btn btn-sm btn-danger" @click="store.executeAction('clear-logs')">Clear</button>
        </div>
      </div>
      <input
        v-model="logSearch"
        type="text"
        placeholder="Filter logs…"
        class="log-filter"
      />
      <div class="log-box" ref="logContainer">
        <template v-if="filteredLogLines.length">
          <div
            v-for="(line, i) in filteredLogLines"
            :key="i"
            class="log-line"
            :class="logLineClass(line)"
          >{{ line }}</div>
        </template>
        <div v-else class="log-empty">No log entries.</div>
      </div>
    </section>

    <!-- Port Modal -->
    <Modal :show="showPortModal" title="Change Port" @close="showPortModal = false">
      <div class="modal-body-inner">
        <div class="port-presets">
          <button
            v-for="p in [18800, 18801, 8080, 9090]"
            :key="p"
            @click="newPort = String(p)"
            class="chip"
          >{{ p }}</button>
        </div>
        <input v-model="newPort" type="number" min="1" max="65535" class="port-input" />
      </div>
      <template #actions>
        <button class="btn btn-sm" @click="showPortModal = false">Cancel</button>
        <button class="btn btn-primary btn-sm" @click="savePort">Save &amp; Restart</button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted } from 'vue';
import { usePicoClawStore } from '@/stores/PicoClawStore';
import Modal from '@/components/ui/Modal.vue';

const store = usePicoClawStore();

function wrapperLabel(val) {
  if (val === 'ready') return 'Ready (17)';
  if (val === 'missing') return 'Not installed';
  if (val === 'termux-not-found') return 'Termux not found';
  if (val?.startsWith('partial-')) return `Partial (${val.slice(8).replace('-of-', '/')})`;
  return val || '—';
}

async function openDashboard() {
  if (!store.isRunning) {
    await store.executeAction('start');
    await new Promise((r) => setTimeout(r, 600));
  }
  const url = await store.control('url');
  window.location.assign(url);
}

function copyText(txt) {
  if (!txt) return;
  navigator.clipboard.writeText(txt);
  store.toastMessage = 'Copied to clipboard';
}

const showPortModal = ref(false);
const newPort = ref(store.status.PORT || '18800');

async function savePort() {
  const p = parseInt(newPort.value, 10);
  if (isNaN(p) || p < 1 || p > 65535) {
    store.errorMessage = 'Invalid port (1-65535).';
    return;
  }
  showPortModal.value = false;
  await store.executeAction('port', String(p));
}

function triggerRestore() {
  const path = window.prompt('Backup file path (.tar.gz):', '/sdcard/Download/picoclaw-backup-latest.tar.gz');
  if (path && path.trim()) store.executeAction('restore', path.trim());
}

function cleanLogLine(rawLine) {
  if (!rawLine) return '';
  // 1. Strip ANSI escape sequences and color codes like [38;2;213;70;70m
  let clean = rawLine
    .replace(/[\u001b\x1b]\[[0-9;]*[a-zA-Z]/g, '')
    .replace(/\[\d{1,3}(?:;\d{1,3})*m/g, '')
    .replace(/[\u0000-\u0009\u000B-\u001F\u007F-\u009F]/g, '');

  // 2. Strip lines that consist solely of box drawing / ASCII banner characters
  clean = clean.replace(/^[█░▒▓┌┐└┘├┤┬┴┼═║╒╓╔╕╖╗╘╙╚╛╜╝╞╟╠╡╢╣╤╥╦╧╨╩╪╫╬▔▕▖▗▘▙▚▛▜▝▞▟\s]+$/, '');
  return clean.trim();
}

const logSearch = ref('');
const logContainer = ref(null);

const filteredLogLines = computed(() => {
  if (!store.logs) return [];
  const lines = store.logs
    .split('\n')
    .map(cleanLogLine)
    .filter((l) => l.length > 0);
  if (!logSearch.value.trim()) return lines;
  const q = logSearch.value.toLowerCase();
  return lines.filter((l) => l.toLowerCase().includes(q));
});

function logLineClass(line) {
  if (line.includes('ERR') || line.includes('error') || line.includes('gagal')) return 'log-err';
  if (line.includes('WRN') || line.includes('Warning')) return 'log-warn';
  if (line.includes('aktif') || line.includes('RUNNING') || line.includes('PID')) return 'log-ok';
  return '';
}

function scrollLogBottom() {
  nextTick(() => {
    if (logContainer.value) logContainer.value.scrollTop = logContainer.value.scrollHeight;
  });
}

watch(() => store.logs, scrollLogBottom);
onMounted(scrollLogBottom);

const paths = computed(() => [
  { label: 'Data & Workspace', value: '/data/adb/picoclaw' },
  { label: 'Service Log', value: store.status.LOG },
  { label: 'Config', value: store.status.CONFIG },
]);
</script>
