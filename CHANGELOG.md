# PicoClaw Module 1.0.10

Dibangun dari fork [`45a91170673aa8cec55e395c8bf446179e623156`](https://github.com/As-tsaqib/picoclaw/commit/45a91170673aa8cec55e395c8bf446179e623156), ref `main`, dengan versi binary `nightly-2-g45a91170`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

fix(telegram): harden search continuation UX (#20)

* chore(pr20): apply bounded search continuation patch

* chore(pr20): arm PR-scoped continuation patch runner

* chore(pr20): align help acceptance with picker usage

* fix(telegram): harden search interaction continuations

* test(telegram): cover search continuation lifecycle

* test(agent): cover search semantics and stable navigation

* test(agent): fix model state decoding import

* chore(pr20): validate and format acceptance coverage

* test(telegram): validate search continuation acceptance

* test(telegram): cover private memory search continuation

* test(agent): cover bounded memory search input

* chore(pr20): finalize exact lint and acceptance validation

* chore(pr20): trigger exact lint finalizer

* chore(pr20): run registered exact formatter gate

* chore(pr20): allow explicit reopened formatter trigger

* chore(pr20): arm push-based exact lint finalizer

* chore(pr20): trigger push-based exact lint finalizer

* style(telegram): normalize checkpoint semantic service

* chore(pr20): replace stale lint finalizer

* chore(pr20): arm simplified push lint finalizer

* chore(pr20): trigger armed push lint finalizer

* style(telegram): wrap stable skill detail state

* chore(pr20): fix lint finalizer workflow syntax

* chore(pr20): trigger valid push lint finalizer

* test(telegram): finalize continuation hardening coverage

* chore(pr20): arm actionlint-safe exact formatter gate

* test(telegram): finalize continuation hardening coverage

* chore(pr20): remove unrelated formatter drift

* test(agent): pin search callback to bound session

* test(agent): align bound-session fixture with scoped session tests

* fix(telegram): require continuation interaction establishment

* fix(telegram): make append continuation delivery strict

* test(telegram): preserve old menu when continuation setup fails

* fix(telegram): bind continuation postcondition to message identity

* test(telegram): cover continuation registration eviction

* fix(telegram): scope continuation cleanup to route

* fix(telegram): require actionable continuation markup

* test(telegram): require actionable continuation keyboard

* fix(checkpoint): preserve page when backing from detail

* test(checkpoint): assert detail back preserves origin page

* fix(use): document no-argument fallback flow

* test(use): require no-argument fallback guidance

---------

Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>

