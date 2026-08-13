#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

command -v npm >/dev/null 2>&1 || {
  printf 'error: npm diperlukan untuk memverifikasi WebUI\n' >&2
  exit 1
}

WEBUI_DIR="$REPO_DIR/webui"
[[ -f $WEBUI_DIR/package-lock.json ]] || {
  printf 'error: webui/package-lock.json tidak ditemukan\n' >&2
  exit 1
}

TEMP_ROOT=${TMPDIR:-}
if [[ -z $TEMP_ROOT ]]; then
  TEMP_ROOT="$REPO_DIR/.cache"
elif [[ $TEMP_ROOT != /* ]]; then
  TEMP_ROOT="$PWD/$TEMP_ROOT"
fi
if ! mkdir -p -- "$TEMP_ROOT" || [[ ! -w $TEMP_ROOT ]]; then
  TEMP_ROOT="$REPO_DIR/.cache"
  mkdir -p -- "$TEMP_ROOT"
fi
OUTPUT_DIR="$(mktemp -d "$TEMP_ROOT/picoclaw-webui.XXXXXX")"
OUTPUT_DIR="$(cd -- "$OUTPUT_DIR" && pwd -P)"
cleanup() {
  rm -rf -- "$OUTPUT_DIR"
}
trap cleanup EXIT

npm ci --prefix "$WEBUI_DIR"
PICOCLAW_WEBUI_OUT_DIR="$OUTPUT_DIR" npm --prefix "$WEBUI_DIR" run build

diff -qr -- "$OUTPUT_DIR" "$REPO_DIR/module/webroot" || {
  printf 'error: module/webroot tidak sinkron dengan hasil build webui/.\n' >&2
  printf 'Jalankan npm ci --prefix webui && npm --prefix webui run build untuk memperbarui asset release.\n' >&2
  exit 1
}

printf 'WebUI build dan asset module/webroot sinkron.\n'
