#!/usr/bin/env bash

set -Eeuo pipefail

UPSTREAM_TAG=${1:-}
MODULE_VERSION=${2:-}
UPSTREAM_NOTES=${3:-}
OUTPUT=${4:-}

[[ -n $UPSTREAM_TAG && -n $MODULE_VERSION && -f $UPSTREAM_NOTES && -n $OUTPUT ]] || {
  printf 'Usage: %s UPSTREAM_TAG MODULE_VERSION UPSTREAM_NOTES OUTPUT\n' "$0" >&2
  exit 2
}

{
  printf '# PicoClaw Module %s\n\n' "$MODULE_VERSION"
  # Backticks below are literal Markdown delimiters, not shell substitutions.
  # shellcheck disable=SC2016
  printf 'Dibangun otomatis dari release upstream [`%s`](https://github.com/sipeed/picoclaw/releases/tag/%s).\n\n' \
    "$UPSTREAM_TAG" "$UPSTREAM_TAG"
  printf '## Instalasi\n\n'
  # shellcheck disable=SC2016
  printf '1. Unduh ZIP `PicoClaw-Module-*-arm64.zip`.\n'
  printf '2. Pasang melalui KSU Next Manager dan reboot.\n'
  # shellcheck disable=SC2016
  printf '3. Jalankan `picoclaw version` di Termux dan izinkan akses root satu kali.\n'
  # shellcheck disable=SC2016
  printf '4. Buka WebUI modul atau `http://127.0.0.1:18800`.\n\n'
  printf '> Target: Android ARM64. Binary core dan launcher web dikompilasi dari source tag upstream.\n\n'
  printf '## Changelog upstream\n\n'
  cat -- "$UPSTREAM_NOTES"
  printf '\n'
} > "$OUTPUT"
