#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "command '$1' tidak ditemukan"
}

validate_upstream_tag() {
  local tag=$1
  [[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] ||
    die "tag upstream tidak valid: $tag"
}

load_release_metadata() {
  local tag=$1
  local revision version major minor patch base

  validate_upstream_tag "$tag"
  revision="$(tr -d '[:space:]' < "$REPO_DIR/MODULE_REVISION")"
  [[ $revision =~ ^[0-9]+$ ]] || die "MODULE_REVISION harus berupa integer"
  (( revision >= 1 && revision <= 99 )) || die "MODULE_REVISION harus berada pada 1..99"

  base=${tag#v}
  base=${base%%-*}
  IFS=. read -r major minor patch <<< "$base"
  [[ $major =~ ^[0-9]+$ && $minor =~ ^[0-9]+$ && $patch =~ ^[0-9]+$ ]] ||
    die "tag upstream bukan semver yang didukung: $tag"
  (( major <= 20 && minor <= 999 && patch <= 999 )) ||
    die "komponen versi terlalu besar untuk versionCode Android"

  version="${tag}-r${revision}"

  UPSTREAM_TAG=$tag
  MODULE_REVISION=$revision
  MODULE_VERSION=$version
  VERSION_CODE=$((10#$major * 100000000 + 10#$minor * 100000 + 10#$patch * 100 + 10#$revision))
  ASSET_NAME="PicoClaw-Module-${MODULE_VERSION}-arm64.zip"

  export UPSTREAM_TAG MODULE_REVISION MODULE_VERSION VERSION_CODE ASSET_NAME
}
