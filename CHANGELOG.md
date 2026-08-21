# PicoClaw Module 1.0.12

Dibangun dari fork [`197f457a7bc4b4238bcb230d1a1e32bbc270590f`](https://github.com/As-tsaqib/picoclaw/commit/197f457a7bc4b4238bcb230d1a1e32bbc270590f), ref `main`, dengan versi binary `nightly-1-g197f457a`.

## Instalasi

1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.
2. Pasang melalui KSU Next Manager dan reboot.
3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.
4. Buka WebUI modul atau `http://127.0.0.1:18800`.

> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).

> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.

Unify slash-command semantics and safety (#22)

* refactor(commands): add canonical discovery metadata

* feat(commands): add safe user error boundary

* fix(commands): fail closed on unknown slash commands

* fix(commands): separate new from clear semantics

* feat(commands): add session new shortcut

* feat(commands): register canonical new command

* fix(commands): sanitize session command errors

* refactor(commands): expand typed semantic requests

* refactor(commands): route memory through typed semantic API

* refactor(commands): formalize switch compatibility

* feat(commands): canonicalize checkpoint archive

* fix(commands): sanitize canonical model semantics

* feat(commands): derive rich help from registry metadata

* feat(bus): add reusable structured card typography

* feat(commands): apply contextual card headers

* feat(commands): add lightweight accurate onboarding

* refactor(commands): clarify mcp inventory and detail semantics

* fix(agent): sanitize user-facing processing errors

* feat(commands): normalize use command intent parsing

* docs(commands): clarify normalized use forms

* refactor(agent): centralize typed memory semantics

* refactor(agent): route memory callbacks through typed semantics

* refactor(agent): use typed memory callback router

* refactor(commands): normalize use intent and wire typed memory semantics

* fix(commands): return structured skill picker correctly

* test(commands): cover slash semantic consistency contracts

* test(agent): preserve use helper compatibility during semantic consolidation

* fix(commands): sanitize discovery errors

* fix(commands): keep readable help fallback compatible

* test(commands): align switch replacement with canonical model syntax

* test(agent): assert user-facing provider errors are sanitized

* fix(discovery): distinguish MCP status from inventory

* fix(discovery): layer MCP status semantics after base discovery

* fix(commands): sanitize show errors and use card headers

* style(commands): gofmt structured card helpers

* fix(commands): preserve use help compatibility wording

* fix(commands): preserve MCP tool detail compatibility

* fix(commands): unify slash-command semantics and safety

This aligns the test assertions with the final normative semantics:
- /switch model delegates to ModelCommand
- /memory routes via typed MemoryCommand
- Unknown slash commands fail closed
- Remove dead memory and structured format helpers
- Align user-facing error formatting assertions
- Checkpoint archive semantic alias checks

* style: fix linter errors (golines, unused, misspell)

* style: fix remaining golines and unused warnings

* style: fix remaining golines and gci formatting issues

* style: wrap MCP tool sorting comparator

Keep the MCP command handler compatible with the repository's golines validation.

* style: wrap MCP detail response

Keep the MCP command handler compliant with the repository's golines validation.

* fix(commands): close semantic consistency audit gaps

Sanitize remaining command errors, normalize contextual card typography at text and callback presentation boundaries, group structured help by canonical categories, and add AgentLoop /new safety coverage.

* fix: complete final slash command validation

Resolve the remaining formatter and structured help test failures without changing command semantics.

* fix(telegram): center native table headers

Center Telegram native rich-table header cells while preserving left-aligned body cells and existing vertical alignment. Add focused renderer coverage for alignment, captions, table styling, values, and contextual headers.

* style(telegram): format native table alignment test

---------

Co-authored-by: Assaqib <264941327+As-tsaqib@users.noreply.github.com>

