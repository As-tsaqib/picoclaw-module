#!/usr/bin/env bash

set -Eeuo pipefail

VERSION=${1:-}
VERSION_CODE=${2:-}
ZIP_URL=${3:-}
CHANGELOG_URL=${4:-}
OUTPUT=${5:-}

[[ -n $VERSION && $VERSION_CODE =~ ^[0-9]+$ && -n $ZIP_URL && -n $CHANGELOG_URL && -n $OUTPUT ]] || {
  printf 'Usage: %s VERSION VERSION_CODE ZIP_URL CHANGELOG_URL OUTPUT\n' "$0" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || {
  printf 'error: jq tidak ditemukan\n' >&2
  exit 1
}

OUTPUT_DIR="$(dirname -- "$OUTPUT")"
mkdir -p -- "$OUTPUT_DIR"
TEMP_FILE="$(mktemp "$OUTPUT_DIR/.update-json.XXXXXX")"
cleanup() {
  rm -f -- "$TEMP_FILE"
}
trap cleanup EXIT

jq -n \
  --arg version "$VERSION" \
  --argjson versionCode "$VERSION_CODE" \
  --arg zipUrl "$ZIP_URL" \
  --arg changelog "$CHANGELOG_URL" \
  --arg banner "https://raw.githubusercontent.com/As-tsaqib/picoclaw-module/main/banner.png" \
  '{version: $version, versionCode: $versionCode, zipUrl: $zipUrl, changelog: $changelog, banner: $banner}' \
  > "$TEMP_FILE"
mv -f -- "$TEMP_FILE" "$OUTPUT"
