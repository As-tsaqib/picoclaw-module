# PicoClaw Module 1.0.0

Dibangun dari fork [`6e005116e02aa2152bd56e0f6772b9db04f6663e`](https://github.com/As-tsaqib/picoclaw/commit/6e005116e02aa2152bd56e0f6772b9db04f6663e), ref `main`, dengan versi binary `6e005116`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat(web): add advanced configuration dashboard (#3)

Separate upstream Settings from a dedicated Advanced dashboard for runtime concurrency, curated memory and recall, checkpoints, and evolution controls. Includes scoped backend APIs, merge-patch persistence, responsive localized UI, and regression coverage.\n\nValidated by GitHub Actions; developed with AI assistance.

