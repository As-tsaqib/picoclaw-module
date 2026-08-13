#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

PICOCLAW_FORK_REPOSITORY='As-tsaqib/picoclaw'
PICOCLAW_FORK_URL='https://github.com/As-tsaqib/picoclaw'
export PICOCLAW_FORK_MODULE_PATH='github.com/As-tsaqib/picoclaw'

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "command '$1' tidak ditemukan"
}

validate_source_ref() {
  local source_ref=$1
  [[ $source_ref =~ ^[A-Za-z0-9._/-]+$ && $source_ref != -* && $source_ref != */ &&
    $source_ref != /* && $source_ref != *..* && $source_ref != *//* &&
    $source_ref != *'@{'* ]] ||
    die "source ref tidak valid: $source_ref"
}

validate_module_version() {
  local version=$1
  local major minor patch

  [[ $version =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] ||
    die "MODULE_VERSION harus berupa SemVer x.y.z tanpa prefix v: $version"
  IFS=. read -r major minor patch <<< "$version"
  (( 10#$major <= 2000 && 10#$minor <= 999 && 10#$patch <= 999 )) ||
    die "komponen MODULE_VERSION terlalu besar untuk versionCode Android: $version"
}

module_version_code() {
  local version=$1
  local major minor patch

  IFS=. read -r major minor patch <<< "$version"
  printf '%s\n' "$((10#$major * 1000000 + 10#$minor * 1000 + 10#$patch))"
}

bump_module_patch() {
  local version=$1
  local major minor patch

  validate_module_version "$version"
  IFS=. read -r major minor patch <<< "$version"
  patch=$((10#$patch + 1))
  if (( patch > 999 )); then
    patch=0
    minor=$((10#$minor + 1))
  fi
  if (( minor > 999 )); then
    minor=0
    major=$((10#$major + 1))
  fi
  validate_module_version "$major.$minor.$patch"
  printf '%s.%s.%s\n' "$major" "$minor" "$patch"
}

validate_source_repository_url() {
  local source_url=$1
  source_url=${source_url%/}
  source_url=${source_url%.git}
  case "$source_url" in
    "$PICOCLAW_FORK_URL"|"git@github.com:$PICOCLAW_FORK_REPOSITORY") ;;
    *)
      die "source repository harus $PICOCLAW_FORK_URL (diberikan: $1)"
      ;;
  esac
}

source_tree_is_fork() {
  local source_dir=$1
  local remote_url normalized_url

  remote_url="$(git -C "$source_dir" remote get-url origin 2>/dev/null || true)"
  normalized_url=${remote_url%/}
  normalized_url=${normalized_url%.git}
  case "$normalized_url" in
    "$PICOCLAW_FORK_URL"|"git@github.com:$PICOCLAW_FORK_REPOSITORY")
      return 0
      ;;
  esac

  return 1
}

require_fork_source_tree() {
  local source_dir=$1
  source_tree_is_fork "$source_dir" ||
    die "SOURCE_DIR harus merupakan checkout Git dari $PICOCLAW_FORK_URL"
}

load_module_metadata() {
  local version

  version="$(tr -d '[:space:]' < "$REPO_DIR/MODULE_VERSION")"
  validate_module_version "$version"

  MODULE_VERSION=$version
  VERSION_CODE=$(module_version_code "$version")
  ASSET_NAME="PicoClaw-Module-${MODULE_VERSION}-arm64.zip"

  export MODULE_VERSION VERSION_CODE ASSET_NAME
}
