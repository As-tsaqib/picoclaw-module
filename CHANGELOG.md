# PicoClaw Module 1.0.8

Dibangun dari fork [`b099278e41ab3a4913841e39c6a7f560f11ed96f`](https://github.com/As-tsaqib/picoclaw/commit/b099278e41ab3a4913841e39c6a7f560f11ed96f), ref `main`, dengan versi binary `nightly-3-gb099278e`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

fix(web): retry gateway autostart after boot readiness (#18)

Arm gateway keep-alive before boot readiness validation so the launcher watchdog retries startup after transient configuration or credential readiness failures. Preserve explicit stop behavior and cover recovery with a regression test.

