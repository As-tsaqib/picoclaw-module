import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import * as KSU from '@/helpers/KernelSU';

const CONTROL_BIN = '/data/adb/modules/picoclaw/control.sh';

export const usePicoClawStore = defineStore('picoclaw', () => {
  const status = ref({
    RUNNING: '0',
    PID: '',
    AUTOSTART: '1',
    HOST: '127.0.0.1',
    PORT: '18800',
    URL: 'http://127.0.0.1:18800',
    WRAPPERS: '—',
    VERSION: '—',
    UPSTREAM: '—',
    CONFIG: '/data/adb/picoclaw/config.json',
    LOG: '/data/adb/picoclaw/logs/launcher-module.log',
  });

  const logs = ref('Log belum tersedia.');
  const logLines = ref('80');
  const busy = ref(false);
  const toastMessage = ref('');
  const errorMessage = ref('');

  const isRunning = computed(() => status.value.RUNNING === '1');
  const isAutostart = computed(() => status.value.AUTOSTART === '1');

  function shellQuote(val) {
    return `'${String(val).replaceAll("'", "'\\''")}'`;
  }

  async function control(...args) {
    const cmd = [CONTROL_BIN, ...args].map(shellQuote).join(' ');
    const res = await KSU.exec(cmd);
    if (res.errno !== 0) {
      throw new Error(res.stderr || res.stdout || `Perintah gagal (${res.errno})`);
    }
    return res.stdout.trim();
  }

  function parseStatusOutput(raw) {
    const parsed = {};
    for (const line of raw.split('\n')) {
      const idx = line.indexOf('=');
      if (idx > 0) {
        parsed[line.slice(0, idx)] = line.slice(idx + 1);
      }
    }
    return parsed;
  }

  async function refresh({ quiet = false } = {}) {
    try {
      const [statusRaw, logRaw] = await Promise.all([
        control('status'),
        control('logs', logLines.value),
      ]);
      status.value = parseStatusOutput(statusRaw);
      logs.value = logRaw || 'Log belum tersedia.';
    } catch (err) {
      if (!quiet) errorMessage.value = err.message;
    }
  }

  async function executeAction(action, ...args) {
    busy.value = true;
    errorMessage.value = '';
    toastMessage.value = '';
    try {
      let output = '';
      switch (action) {
        case 'start':
        case 'stop':
        case 'restart':
          output = await control(action);
          break;
        case 'autostart':
          output = await control('autostart', args[0] ? 'on' : 'off');
          break;
        case 'port':
          output = await control('port', args[0]);
          break;
        case 'wrappers':
          output = await control('wrappers', 'install');
          break;
        case 'backup':
          output = await control('backup', args[0] || '');
          break;
        case 'restore':
          output = await control('restore', args[0]);
          break;
        case 'clear-logs':
          output = await control('logs', 'clear');
          break;
        default:
          throw new Error(`Aksi tidak dikenal: ${action}`);
      }
      await refresh({ quiet: true });
      if (output) {
        const lastLine = output.split('\n').at(-1);
        toastMessage.value = lastLine;
        KSU.toast(lastLine);
      }
      return output;
    } catch (err) {
      errorMessage.value = err.message;
      throw err;
    } finally {
      busy.value = false;
    }
  }

  return {
    status,
    logs,
    logLines,
    busy,
    toastMessage,
    errorMessage,
    isRunning,
    isAutostart,
    control,
    refresh,
    executeAction,
  };
});
