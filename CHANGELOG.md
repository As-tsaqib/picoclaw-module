# PicoClaw Module 1.0.7

Dibangun dari fork [`b7fe148714b675a2befc26d86e7f8d09a7769d08`](https://github.com/As-tsaqib/picoclaw/commit/b7fe148714b675a2befc26d86e7f8d09a7769d08), ref `main`, dengan versi binary `nightly-2-gb7fe1487`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat(telegram): add interactive command UX and formatted ephemeral fallback (#17)

Implement receiver-safe formatted ephemeral StructuredContent fallback, secure interactive /memory UX, compact /help, and related privacy/callback hardening while preserving existing command compatibility and native Rich Message behavior.

