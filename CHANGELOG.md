# PicoClaw Module 1.0.9

Dibangun dari fork [`8d80aa544f77b6d9ac218893c8589a687f076ee7`](https://github.com/As-tsaqib/picoclaw/commit/8d80aa544f77b6d9ac218893c8589a687f076ee7), ref `main`, dengan versi binary `nightly-1-g8d80aa54`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat(telegram): add interactive skill and checkpoint flows (#19)

* chore(pr19): stage exact interaction patch

* feat(telegram): add skill and checkpoint interactions

* fix(telegram): bound interactive skill search query

* chore(pr19): stage PR17 route restore

* fix(telegram): preserve PR17 topic route binding

* chore(ci): revalidate final interaction tree

* style(telegram): gofmt skill interaction constants

* chore(pr19): stage exact lint normalization

* chore(pr19): arm exact lint normalization

* chore(pr19): run exact lint normalizer

* chore(pr19): finalize lint normalization runner

* chore(ci): restore build workflow

* chore(ci): remove PR19 lint helper

* test(telegram): stage final interaction acceptance coverage

* chore(ci): make PR19 formatter finalizer bounded

* style(telegram): fix checkpoint command lint

* style(telegram): wrap checkpoint command definitions

* style(telegram): format interaction tests

* style(telegram): format checkpoint interaction flow

* style(telegram): format prompt ownership test

* style(telegram): format skill interaction flow

* chore(ci): remove temporary PR19 formatter

* chore(ci): run bounded PR19 formatter

* style(telegram): finalize interaction formatting

* chore(ci): validate final PR19 head

---------

Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>

