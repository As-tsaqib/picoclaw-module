# PicoClaw Module 1.0.11

Dibangun dari fork [`c4699a43eecb83dafb18e416fbe6733b12e403df`](https://github.com/As-tsaqib/picoclaw/commit/c4699a43eecb83dafb18e416fbe6733b12e403df), ref `main`, dengan versi binary `nightly-3-gc4699a43`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat(telegram): add interactive discovery and status UX (#21)

* feat(commands): add discovery status semantics

* feat(commands): add discovery dashboard adapter

* feat(commands): make show session-aware and interactive

* feat(commands): delegate discovery catalogs

* refactor(commands): make channel checks read only

* fix(commands): sort agent discovery output

* fix(commands): sort MCP discovery output

* feat(agent): allowlist discovery callbacks

* feat(agent): configure session-bound discovery semantics

* feat(agent): add discovery and status interaction domain

* fix(commands): keep model inventory truthful

* fix(commands): sanitize read-only channel status failures

* test(commands): cover discovery and read-only status semantics

* test(agent): cover discovery status interaction semantics

* test(telegram): cover discovery status interaction transport

* fix(telegram): admit bound discovery interactions

* test(agent): prove discovery refresh and domain handoff authority

* test(telegram): reject stale discovery tokens

* style(agent): gofmt discovery interaction tests

* feat(agent): expose read-only channel status source

* feat(agent): delegate channel status snapshot

* test(agent): satisfy channel status manager contract

* test(agent): fix channel manager status double

* fix(commands): preserve list help wording

* test(commands): align check coverage with read-only status

* test(telegram): deduplicate discovery binding matrix

* test(commands): format discovery handler setup

* fix(commands): preserve show model fallback compatibility

* style(telegram): wrap discovery interaction transport

* style(commands): wrap unknown channel status fixture

* fix(agent): align show-model test assertions with display-formatted provider names

The /show model path now uses displayProvider() which title-cases
provider names (e.g. 'openrouter' -> 'Openrouter'). The fallback
line assembled by prependCurrentModelFallback reads the formatted
name from the table rows, so the expected test strings must match.

---------

Co-authored-by: Assaqib <264941327+As-tsaqib@users.noreply.github.com>

