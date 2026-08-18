# PicoClaw Module 1.0.4

Dibangun dari fork [`31d584912e0d9cac5b3701ea0df210f5d86db23a`](https://github.com/As-tsaqib/picoclaw/commit/31d584912e0d9cac5b3701ea0df210f5d86db23a), ref `main`, dengan versi binary `nightly-2-g31d58491`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

fix: harden Antigravity auth and model discovery (#8)

Hardens Antigravity OAuth refresh coordination, token rotation, HTTP 401 recovery, dynamic model discovery, cache/account isolation, cancellation, and credential safety while preserving existing session-scoped model/session behavior.

