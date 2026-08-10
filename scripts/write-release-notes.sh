#!/usr/bin/env bash

set -Eeuo pipefail

UPSTREAM_TAG=${1:-}
MODULE_VERSION=${2:-}
UPSTREAM_NOTES=${3:-}
OUTPUT=${4:-}
SOURCE_REPOSITORY=${5:-As-tsaqib/picoclaw}
SOURCE_COMMIT=${6:-unknown}

[[ -n $UPSTREAM_TAG && -n $MODULE_VERSION && -f $UPSTREAM_NOTES && -n $OUTPUT ]] || {
  printf 'Usage: %s UPSTREAM_TAG MODULE_VERSION UPSTREAM_NOTES OUTPUT\n' "$0" >&2
  exit 2
}

{
  printf '# PicoClaw Module %s\n\n' "$MODULE_VERSION"
  # Backticks below are literal Markdown delimiters, not shell substitutions.
  # shellcheck disable=SC2016
  printf 'Berbasis release upstream [`%s`](https://github.com/sipeed/picoclaw/releases/tag/%s), lalu dibangun dari fork kustom [`%s`](https://github.com/%s/commit/%s).\n\n' \
    "$UPSTREAM_TAG" "$UPSTREAM_TAG" "$SOURCE_COMMIT" "$SOURCE_REPOSITORY" "$SOURCE_COMMIT"
  printf '## Instalasi\n\n'
  # shellcheck disable=SC2016
  printf '1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.\n'
  printf '2. Pasang melalui KSU Next Manager dan reboot.\n'
  # shellcheck disable=SC2016
  printf '3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.\n'
  # shellcheck disable=SC2016
  printf '4. Buka WebUI modul atau `http://127.0.0.1:18800`.\n\n'
  printf '> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source fork kustom dengan resolver DNS native Android (Bionic/netd).\n\n'
  printf '> Build menerapkan patch kompatibilitas system tray Android yang tersedia di repo modul.\n\n'
  cleaned_notes="$(python3 "$SCRIPT_DIR/ci/clean-release-notes.py" < "$UPSTREAM_NOTES" 2>/dev/null || cat -- "$UPSTREAM_NOTES")"
  if [ -n "$cleaned_notes" ]; then
    printf '%s\n' "$cleaned_notes"
  else
    printf '[Full Changelog](https://github.com/sipeed/picoclaw/releases/tag/%s)\n' "$UPSTREAM_TAG"
  fi
  printf '\n'
} > "$OUTPUT"
