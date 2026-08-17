# PicoClaw Module 1.0.3

Dibangun dari fork [`9b7d11f0dffa13bf1363acd983f5a1e9445c5249`](https://github.com/As-tsaqib/picoclaw/commit/9b7d11f0dffa13bf1363acd983f5a1e9445c5249), ref `main`, dengan versi binary `nightly-1-g9b7d11f0`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat: add session-scoped model dashboard

Adds session-scoped model selection, Telegram model dashboard hardening, persistent credential-free model overrides, provider discovery/lifecycle hardening, and scoped Telegram session actions.

