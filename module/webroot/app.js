import { exec, hasKernelSUBridge, moduleInfo, toast } from "./kernelsu.js";

const CONTROL = "/data/adb/modules/picoclaw/control.sh";

const elements = {
  statusDot: document.querySelector("#status-dot"),
  statusText: document.querySelector("#status-text"),
  statusDetail: document.querySelector("#status-detail"),
  version: document.querySelector("#version"),
  upstream: document.querySelector("#upstream"),
  port: document.querySelector("#port"),
  wrappers: document.querySelector("#wrappers"),
  autostart: document.querySelector("#autostart"),
  log: document.querySelector("#log"),
  message: document.querySelector("#message"),
  buttons: [...document.querySelectorAll("button[data-action]")],
};

let latestStatus = {};
let busy = false;

function shellQuote(value) {
  return `'${String(value).replaceAll("'", "'\\''")}'`;
}

async function control(...args) {
  const command = [CONTROL, ...args].map(shellQuote).join(" ");
  const result = await exec(command);
  if (result.errno !== 0) {
    throw new Error(result.stderr || result.stdout || `Command gagal (${result.errno})`);
  }
  return result.stdout.trim();
}

function parseStatus(output) {
  const status = {};
  for (const line of output.split("\n")) {
    const separator = line.indexOf("=");
    if (separator > 0) {
      status[line.slice(0, separator)] = line.slice(separator + 1);
    }
  }
  return status;
}

function wrapperLabel(value) {
  if (value === "ready") return "Siap";
  if (value === "missing") return "Belum dipasang";
  if (value === "termux-not-found") return "Termux tidak ditemukan";
  if (value?.startsWith("partial-")) return `Sebagian (${value.slice(8).replace("-of-", "/")})`;
  return value || "—";
}

function renderStatus(status) {
  const running = status.RUNNING === "1";
  elements.statusDot.classList.toggle("online", running);
  elements.statusText.textContent = running ? "Launcher aktif" : "Launcher berhenti";
  elements.statusDetail.textContent = running
    ? `PID ${status.PID} · ${status.URL}`
    : "Tekan Start untuk menjalankan dashboard.";
  elements.version.textContent = status.VERSION || "—";
  elements.upstream.textContent = status.UPSTREAM || "—";
  elements.port.textContent = status.PORT || "18800";
  elements.wrappers.textContent = wrapperLabel(status.WRAPPERS);
  elements.autostart.checked = status.AUTOSTART === "1";
  document.querySelector('[data-action="start"]').disabled = running || busy;
  document.querySelector('[data-action="stop"]').disabled = !running || busy;
}

function setBusy(value) {
  busy = value;
  document.body.classList.toggle("busy", value);
  for (const button of elements.buttons) {
    button.disabled = value;
  }
  if (!value && Object.keys(latestStatus).length > 0) {
    renderStatus(latestStatus);
  }
}

function showMessage(message, isError = false) {
  elements.message.textContent = message;
  elements.message.classList.toggle("error", isError);
  elements.message.hidden = false;
  window.clearTimeout(showMessage.timer);
  showMessage.timer = window.setTimeout(() => {
    elements.message.hidden = true;
  }, 4500);
}

async function refresh({ quiet = false } = {}) {
  try {
    const [statusOutput, logOutput] = await Promise.all([
      control("status"),
      control("logs", "80"),
    ]);
    latestStatus = parseStatus(statusOutput);
    renderStatus(latestStatus);
    elements.log.textContent = logOutput || "Log belum tersedia.";
  } catch (error) {
    if (!quiet) showMessage(error.message, true);
    elements.statusText.textContent = "Status tidak tersedia";
    elements.statusDetail.textContent = error.message;
  }
}

async function runAction(action) {
  setBusy(true);
  try {
    let result = "";
    switch (action) {
      case "start":
      case "stop":
      case "restart":
        result = await control(action);
        break;
      case "wrappers":
        result = await control("wrappers", "install");
        break;
      case "refresh":
        break;
      case "dashboard": {
        if (latestStatus.RUNNING !== "1") {
          await control("start");
          await new Promise((resolve) => window.setTimeout(resolve, 700));
        }
        const url = await control("url");
        window.location.assign(url);
        return;
      }
      default:
        throw new Error(`Action tidak dikenal: ${action}`);
    }
    await refresh({ quiet: true });
    if (result) {
      showMessage(result.split("\n").at(-1));
      toast(result.split("\n").at(-1));
    }
  } catch (error) {
    showMessage(error.message, true);
  } finally {
    setBusy(false);
  }
}

for (const button of elements.buttons) {
  button.addEventListener("click", () => runAction(button.dataset.action));
}

elements.autostart.addEventListener("change", async () => {
  setBusy(true);
  try {
    const mode = elements.autostart.checked ? "on" : "off";
    const result = await control("autostart", mode);
    showMessage(result);
    await refresh({ quiet: true });
  } catch (error) {
    showMessage(error.message, true);
    elements.autostart.checked = !elements.autostart.checked;
  } finally {
    setBusy(false);
  }
});

const info = moduleInfo();
if (info.version) elements.version.textContent = info.version;

if (!hasKernelSUBridge()) {
  showMessage("Halaman ini harus dibuka dari WebUI KSU Next Manager.", true);
  elements.statusText.textContent = "Bridge KSU tidak tersedia";
  elements.statusDetail.textContent = "Buka modul dari KSU Next Manager.";
  setBusy(true);
} else {
  refresh();
  window.setInterval(() => {
    if (!document.hidden && !busy) refresh({ quiet: true });
  }, 10000);
}
