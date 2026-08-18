# PicoClaw Module 1.0.5

Dibangun dari fork [`9cdb96ee63bce5ba9ff7aff9f3e6ef6445922339`](https://github.com/As-tsaqib/picoclaw/commit/9cdb96ee63bce5ba9ff7aff9f3e6ef6445922339), ref `main`, dengan versi binary `nightly-1-g9cdb96ee`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat(memory): add durable personal agent memory (#11)

* ci: add personal memory race acceptance

* feat(memory): add durable personal agent memory

* fix(memory): satisfy static analysis

* chore: retrigger exact-head validation

---------

Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>

