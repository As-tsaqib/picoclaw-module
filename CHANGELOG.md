# PicoClaw Module 1.0.6

Dibangun dari fork [`852f183711307a2ef514426afa7032cfa65141b0`](https://github.com/As-tsaqib/picoclaw/commit/852f183711307a2ef514426afa7032cfa65141b0), ref `main`, dengan versi binary `nightly-1-g852f1837`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

feat: native telegram capabilities and memory hardening v2 (#16)

* feat: native telegram capabilities and personal memory hardening

Add native Telegram interactive capabilities (polls, quizzes, media,
dice, contacts, location) and harden personal memory management.

- Personal memory: cross-channel canonical person scope auto-migration,
  stable logical-turn identity for notifications, deterministic preference
  alias normalization, auto-supersede, and semantic fact consolidation.
- Channel capabilities: declarative route-aware capability authority for
  tool exposure, bounded negative capability cache, and secure fallbacks.
- Telegram native: native poll and quiz tools with official 10.2 schema
  validation, stop_poll lifecycle, non-spoiling quiz fallback with inline
  reveal callbacks, and channel-neutral location/contact/dice tools.
- Dashboard: simplified memory settings with progressive disclosure for
  advanced configurations, truthful owner identity labels, and delta-only
  PATCH requests.

💘 Generated with Crush

Assisted-by: Crush:gemini-3.7-flash-high

* fix(telegram): align poll validation with current Bot API

* fix(telegram): harden poll lifecycle and quiz callbacks

* fix(memory): make notification coalescing lifecycle-owned

* test(memory): prove slow reviewer turn coalescing

* fix(telegram): bind stop poll actions to trusted route

* fix(telegram): scope stop poll tool to trusted route

* fix(telegram): enforce stop poll route proof

* test(telegram): cover stop poll route binding

* feat(memory): add explicit-only capture policy

* feat(memory): carry trusted capture intent in caller scope

* feat(memory): derive explicit capture intent from trusted turn

* feat(memory): enforce explicit-only writes in semantic tool

* feat(memory): disable autonomous reviewer in explicit-only mode

* test(memory): enforce explicit-only capture semantics

* test(memory): classify explicit capture intent narrowly

* feat(telegram): complete channel-neutral rich block model

* feat(telegram): map typed rich blocks to Telego natives

* fix(telegram): correct rich block accounting

* feat(telegram): render typed rich blocks end to end

* test(telegram): cover deterministic rich block fallback

* test(telegram): exercise typed native rich blocks

* feat(telegram): add native rich draft streaming path

* feat(channels): prefer session-aware streaming upgrades

* test(telegram): prove rich draft fallback and final persistence

* fix(telegram): use standard json decode in rich stream tests

* feat(telegram): add channel-neutral live photo payload

* feat(telegram): add semantic live photo tool

* feat(channels): add semantic media delivery hook

* feat(telegram): deliver native live photos safely

* test(telegram): validate live photo envelope semantics

* test(telegram): validate semantic live photo tool

* test(telegram): cover native live photo delivery boundaries

* fix(telegram): keep live photo limits adapter-local

* fix(telegram): validate live photo media shape

* test(polls): bind stop-poll regression to trusted route

* chore(ci): add one-shot PR formatter

* chore: apply Go formatters [formatted]

* chore(ci): remove one-shot formatter

* test(telegram): avoid predeclared identifier shadow

* chore(ci): stage PR16 final hardening

* chore(ci): run PR16 hardening helper safely

* chore(ci): make PR16 final hardening runner observable

* chore(ci): preserve hardening patch literals

* chore(ci): fix PR16 hardening extractor quoting

* chore(ci): fix validated PR16 patch defects

* chore(ci): rerun PR16 hardening after targeted fixes

* chore(ci): publish validated PR16 source without workflow mutation

* fix: close final native capability and memory hardening gaps

* ci: validate PR16 dashboard on exact head

* noop

* do not use

* chore: remove frontend formatter noise

* chore(ci): stage exact PR16 lint hardening

* chore(ci): run exact PR16 lint hardening

* chore(ci): isolate PR16 formatter scope

* fix: satisfy final lint and quiz field hygiene

* chore: remove PR16 lint helper

* chore(ci): stage PR16 capability policy hardening

* chore(ci): validate PR16 capability policy hardening

* chore(ci): fix duplicate route policy patch

* chore(ci): isolate PR16 capability patch preparation

* chore(ci): keep capability helper actionlint-clean

* chore(ci): exclude capability helper self-mutation

* fix: apply native capability admin policy

* chore: remove PR16 capability helper

* ci: validate memory and dashboard changes on pull requests

* chore(ci): stage PR16 frontend formatting fix

* style: format memory dashboard changes

* chore: remove PR16 frontend format helper

* chore(docs): remove duplicate upgrade specification tree

---------

Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>

