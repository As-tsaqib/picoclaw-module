let callbackCounter = 0;

function callbackName(prefix) {
  callbackCounter += 1;
  return `${prefix}_${Date.now()}_${callbackCounter}`;
}

export function hasKernelSUBridge() {
  return typeof window.ksu !== "undefined" && typeof window.ksu.exec === "function";
}

export function exec(command, options = {}) {
  return new Promise((resolve, reject) => {
    if (!hasKernelSUBridge()) {
      reject(new Error("KernelSU / APatch WebUI bridge not available. Open this page from the Manager app."));
      return;
    }

    const name = callbackName("picoclaw_exec");
    window[name] = (errno, stdout, stderr) => {
      delete window[name];
      resolve({ errno, stdout, stderr });
    };

    try {
      window.ksu.exec(command, JSON.stringify(options), name);
    } catch (error) {
      delete window[name];
      reject(error);
    }
  });
}

export function toast(message) {
  if (typeof window.ksu?.toast === "function") {
    window.ksu.toast(String(message));
  }
}

export function moduleInfo() {
  if (typeof window.ksu?.moduleInfo !== "function") {
    return {};
  }
  try {
    return JSON.parse(window.ksu.moduleInfo());
  } catch {
    return {};
  }
}
