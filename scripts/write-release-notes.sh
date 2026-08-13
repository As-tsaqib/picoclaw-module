#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_REF=${1:-}
MODULE_VERSION=${2:-}
SOURCE_NOTES=${3:-}
OUTPUT=${4:-}
SOURCE_REPOSITORY=${5:-As-tsaqib/picoclaw}
SOURCE_COMMIT=${6:-unknown}
BINARY_VERSION=${7:-unknown}

[[ -n $SOURCE_REF && -n $MODULE_VERSION && -f $SOURCE_NOTES && -n $OUTPUT ]] || {
  printf 'Usage: %s SOURCE_REF MODULE_VERSION SOURCE_NOTES OUTPUT [SOURCE_REPOSITORY] [SOURCE_COMMIT] [BINARY_VERSION]\n' "$0" >&2
  exit 2
}

{
  printf '# PicoClaw Module %s\n\n' "$MODULE_VERSION"
  # Backticks below are literal Markdown delimiters, not shell substitutions.
  # shellcheck disable=SC2016
  printf 'Dibangun dari fork [`%s`](https://github.com/%s/commit/%s), ref `%s`, dengan versi binary `%s`.\n\n' \
    "$SOURCE_COMMIT" "$SOURCE_REPOSITORY" "$SOURCE_COMMIT" "$SOURCE_REF" "$BINARY_VERSION"
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
  cleaned_notes="$(python3 "$SCRIPT_DIR/ci/clean-release-notes.py" < "$SOURCE_NOTES" 2>/dev/null || cat -- "$SOURCE_NOTES")"
  if [ -n "$cleaned_notes" ]; then
    printf '%s\n' "$cleaned_notes"
  else
    printf '[Source commit](https://github.com/%s/commit/%s)\n' "$SOURCE_REPOSITORY" "$SOURCE_COMMIT"
  fi
  printf '\n'
} > "$OUTPUT"
