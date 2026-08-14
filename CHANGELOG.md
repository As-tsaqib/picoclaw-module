# PicoClaw Module 1.0.0

Dibangun dari fork [`53b6d6042151512f84dab51cdd19c85e0fa36055`](https://github.com/As-tsaqib/picoclaw/commit/53b6d6042151512f84dab51cdd19c85e0fa36055), ref `main`, dengan versi binary `nightly`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

chore: establish standalone v1.0.0 distribution (#4)

Migrate module, updater, documentation, artifacts, and release workflows to the independently maintained fork. Remove automatic upstream sync and upstream publication dependencies; retain historical attribution and ancestry.

