# PicoClaw Module 1.0.1

Dibangun dari fork [`d9798513286b72d17135d996c22b33f39ecbdd8e`](https://github.com/As-tsaqib/picoclaw/commit/d9798513286b72d17135d996c22b33f39ecbdd8e), ref `main`, dengan versi binary `nightly-1-gd9798513`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat: supervise gateway process

