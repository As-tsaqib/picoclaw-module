# PicoClaw Module 1.0.2

Dibangun dari fork [`707ae510b06d6f6c367e824a1d0a02f8e7a080b6`](https://github.com/As-tsaqib/picoclaw/commit/707ae510b06d6f6c367e824a1d0a02f8e7a080b6), ref `main`, dengan versi binary `nightly-2-g707ae510`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat: add scoped Telegram sessions and rich command responses

