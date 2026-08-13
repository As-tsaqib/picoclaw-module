#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

SOURCE_DIR=${1:-}
SOURCE_REF_INPUT=${2:-main}
OUTPUT_DIR=${3:-"$REPO_DIR/dist"}
SOURCE_COMMIT_INPUT=${4:-${PICOCLAW_SOURCE_COMMIT:-}}

[[ -n $SOURCE_DIR ]] || {
  printf 'Usage: %s SOURCE_DIR [SOURCE_REF] [OUTPUT_DIR] [SOURCE_COMMIT]\n' "$0" >&2
  exit 2
}

load_module_metadata
validate_source_ref "$SOURCE_REF_INPUT"
SOURCE_DIR="$(cd -- "$SOURCE_DIR" && pwd)"

require_command git
require_command go
require_command make
require_command node
require_command pnpm
require_command zip
require_command file

[[ -f $SOURCE_DIR/go.mod ]] || die "go.mod PicoClaw tidak ditemukan di $SOURCE_DIR"
grep -qx 'module github.com/sipeed/picoclaw' "$SOURCE_DIR/go.mod" ||
  die "SOURCE_DIR bukan source tree PicoClaw fork"

source_repository_url="${PICOCLAW_SOURCE_REPOSITORY_URL:-$PICOCLAW_FORK_URL}"
validate_source_repository_url "$source_repository_url"
source_repository_url=$PICOCLAW_FORK_URL
require_fork_source_tree "$SOURCE_DIR"

if [[ -n $(git -C "$SOURCE_DIR" status --porcelain) ]]; then
  die "SOURCE_DIR harus bersih sebelum build"
fi

head_commit="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
if [[ -n $SOURCE_COMMIT_INPUT && $head_commit != "$SOURCE_COMMIT_INPUT" ]]; then
  die "HEAD source ($head_commit) tidak sesuai commit yang diminta ($SOURCE_COMMIT_INPUT)"
fi

binary_version="${PICOCLAW_BINARY_VERSION:-}"
if [[ -z $binary_version ]]; then
  binary_version="$(git -C "$SOURCE_DIR" describe --tags --always --dirty 2>/dev/null || true)"
fi
[[ -n $binary_version && $binary_version != *[[:space:]]* ]] ||
  die "versi binary tidak dapat ditentukan dari source fork"

BUILD_PARENT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/picoclaw-build.XXXXXX")"
BUILD_SOURCE_DIR="$BUILD_PARENT_DIR/source"
cleanup_build_worktree() {
  # Go's module cache intentionally creates read-only files. Restore write
  # permission inside this disposable directory before Git/rm cleans it up.
  # The scope is limited to the temporary build parent created above.
  if [[ -d $BUILD_SOURCE_DIR ]]; then
    chmod -R u+w -- "$BUILD_SOURCE_DIR" >/dev/null 2>&1 || true
  fi
  if git -C "$SOURCE_DIR" worktree list --porcelain |
    grep -Fqx "worktree $BUILD_SOURCE_DIR"; then
    git -C "$SOURCE_DIR" worktree remove --force "$BUILD_SOURCE_DIR" >/dev/null 2>&1 || true
  fi
  chmod -R u+w -- "$BUILD_PARENT_DIR" >/dev/null 2>&1 || true
  rm -rf -- "$BUILD_PARENT_DIR"
}
trap cleanup_build_worktree EXIT

git -C "$SOURCE_DIR" worktree add --detach "$BUILD_SOURCE_DIR" "$head_commit" >/dev/null ||
  die "tidak dapat membuat worktree build sementara"
printf 'Building from disposable worktree %s; fork source tree asli tidak diubah.\n' "$BUILD_SOURCE_DIR"

android_systray_stub="$BUILD_SOURCE_DIR/web/backend/systray_stub_nocgo.go"
android_systray_patch="$REPO_DIR/patches/android-cgo-systray.patch"
legacy_systray_constraint='//go:build (darwin || freebsd || android) && !cgo'
patched_systray_constraint='//go:build android || ((darwin || freebsd) && !cgo)'

if [[ -f $android_systray_stub ]] &&
  grep -Fqx "$legacy_systray_constraint" "$android_systray_stub"; then
  [[ -f $android_systray_patch ]] ||
    die "patch kompatibilitas launcher tidak ditemukan: $android_systray_patch"
  git -C "$BUILD_SOURCE_DIR" apply --unidiff-zero --check "$android_systray_patch" ||
    die "patch kompatibilitas launcher tidak dapat diterapkan ke source ref $SOURCE_REF_INPUT"
  git -C "$BUILD_SOURCE_DIR" apply --unidiff-zero "$android_systray_patch"
  printf 'Applied Android cgo system-tray compatibility patch.\n'
elif [[ -f $android_systray_stub ]] &&
  grep -Fqx "$patched_systray_constraint" "$android_systray_stub"; then
  printf 'Android cgo system-tray compatibility patch is already present.\n'
else
  printf 'Fork system-tray layout changed; compatibility patch not required or no longer applicable.\n'
fi

android_api=${PICOCLAW_ANDROID_API:-21}
[[ $android_api =~ ^[0-9]+$ ]] ||
  die "PICOCLAW_ANDROID_API harus berupa integer"
(( android_api >= 21 && android_api <= 99 )) ||
  die "PICOCLAW_ANDROID_API harus berada pada 21..99"

android_cc=${PICOCLAW_ANDROID_CC:-}
if [[ -z $android_cc ]]; then
  for compiler_candidate in \
    "aarch64-linux-android${android_api}-clang" \
    aarch64-linux-android-clang; do
    if command -v "$compiler_candidate" >/dev/null 2>&1; then
      android_cc=$compiler_candidate
      break
    fi
  done
fi

[[ -n $android_cc ]] ||
  die "compiler Android ARM64 tidak ditemukan; set PICOCLAW_ANDROID_CC ke clang dari Android NDK"
android_cc_path="$(command -v "$android_cc" 2>/dev/null || true)"
[[ -n $android_cc_path && -x $android_cc_path ]] ||
  die "compiler Android ARM64 tidak executable: $android_cc"
android_target="$($android_cc_path -dumpmachine)"
[[ $android_target == aarch64*android* ]] ||
  die "target compiler bukan Android ARM64: $android_target"

printf 'Building PicoClaw source %s (%s) for android/arm64...\n' "$SOURCE_REF_INPUT" "$head_commit"
printf 'Using cgo compiler %s (%s).\n' "$android_cc_path" "$android_target"
CGO_ENABLED=1 CC="$android_cc_path" \
  make -C "$BUILD_SOURCE_DIR" VERSION="$binary_version" build-android-bundle

PICOCLAW_SOURCE_REPOSITORY_URL="$source_repository_url" \
PICOCLAW_SOURCE_REF="$SOURCE_REF_INPUT" \
PICOCLAW_SOURCE_COMMIT="$head_commit" \
PICOCLAW_BINARY_VERSION="$binary_version" \
  bash "$SCRIPT_DIR/package-module.sh" "$BUILD_SOURCE_DIR" "$SOURCE_REF_INPUT" "$OUTPUT_DIR" "$head_commit" "$binary_version"
