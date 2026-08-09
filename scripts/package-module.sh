#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

SOURCE_DIR=${1:-}
UPSTREAM_TAG_INPUT=${2:-}
OUTPUT_DIR=${3:-"$REPO_DIR/dist"}

[[ -n $SOURCE_DIR && -n $UPSTREAM_TAG_INPUT ]] || {
  printf 'Usage: %s SOURCE_DIR UPSTREAM_TAG [OUTPUT_DIR]\n' "$0" >&2
  exit 2
}

load_release_metadata "$UPSTREAM_TAG_INPUT"
SOURCE_DIR="$(cd -- "$SOURCE_DIR" && pwd)"
mkdir -p -- "$OUTPUT_DIR"
OUTPUT_DIR="$(cd -- "$OUTPUT_DIR" && pwd)"

CORE_SOURCE="$SOURCE_DIR/build/picoclaw-android-arm64"
LAUNCHER_SOURCE="$SOURCE_DIR/build/picoclaw-launcher-android-arm64"

[[ -x $CORE_SOURCE ]] || die "binary core tidak ditemukan/executable: $CORE_SOURCE"
[[ -x $LAUNCHER_SOURCE ]] || die "binary launcher tidak ditemukan/executable: $LAUNCHER_SOURCE"
[[ -f $SOURCE_DIR/LICENSE ]] || die "LICENSE upstream tidak ditemukan"

validate_elf_arm64() {
  local binary=$1
  local build_metadata description

  if [[ ${PICOCLAW_SKIP_ELF_CHECK:-0} == 1 ]]; then
    return 0
  fi

  require_command file
  description="$(file -b -- "$binary")"
  [[ $description == *ELF\ 64-bit* && $description == *ARM\ aarch64* ]] ||
    die "$binary bukan ELF Android ARM64: $description"

  require_command go
  build_metadata="$(go version -m "$binary")"
  grep -Fq "github.com/sipeed/picoclaw/pkg/config.Version=$UPSTREAM_TAG" <<< "$build_metadata" ||
    die "$binary tidak memuat metadata versi upstream $UPSTREAM_TAG"
  grep -Fq $'build\tCGO_ENABLED=1' <<< "$build_metadata" ||
    die "$binary tidak dibangun dengan cgo; resolver DNS native Android tidak tersedia"
  grep -Fq $'build\tGOOS=android' <<< "$build_metadata" ||
    die "$binary tidak dibangun untuk GOOS=android"
  grep -Fq $'build\tGOARCH=arm64' <<< "$build_metadata" ||
    die "$binary tidak dibangun untuk GOARCH=arm64"
}

validate_elf_arm64 "$CORE_SOURCE"
validate_elf_arm64 "$LAUNCHER_SOURCE"

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/picoclaw-module.XXXXXX")"
cleanup() {
  rm -rf -- "$STAGE_DIR"
}
trap cleanup EXIT

cp -a -- "$REPO_DIR/module/." "$STAGE_DIR/"
rm -f -- "$STAGE_DIR/bin/.gitkeep"
install -m 0755 -- "$CORE_SOURCE" "$STAGE_DIR/bin/picoclaw"
install -m 0755 -- "$LAUNCHER_SOURCE" "$STAGE_DIR/bin/picoclaw-launcher"
install -m 0644 -- "$REPO_DIR/LICENSE" "$STAGE_DIR/LICENSE.module"
install -m 0644 -- "$SOURCE_DIR/LICENSE" "$STAGE_DIR/LICENSE.picoclaw"
install -m 0644 -- "$REPO_DIR/THIRD_PARTY_NOTICES.md" "$STAGE_DIR/THIRD_PARTY_NOTICES.md"

sed -i \
  -e "s|@MODULE_VERSION@|$MODULE_VERSION|g" \
  -e "s|@VERSION_CODE@|$VERSION_CODE|g" \
  -e "s|@UPSTREAM_TAG@|$UPSTREAM_TAG|g" \
  "$STAGE_DIR/module.prop"

upstream_commit="unknown"
if git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  upstream_commit="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
fi

cat > "$STAGE_DIR/build-info.prop" <<EOF
upstreamRepo=https://github.com/sipeed/picoclaw
upstreamTag=$UPSTREAM_TAG
upstreamCommit=$upstream_commit
moduleVersion=$MODULE_VERSION
moduleRevision=$MODULE_REVISION
androidCgo=1
androidDnsResolver=bionic-netd
EOF

find "$STAGE_DIR" -type d -exec chmod 0755 {} +
find "$STAGE_DIR" -type f -exec chmod 0644 {} +
find "$STAGE_DIR" -type f -name '*.sh' -exec chmod 0755 {} +
chmod 0755 "$STAGE_DIR/bin/picoclaw" "$STAGE_DIR/bin/picoclaw-launcher"
chmod 0755 "$STAGE_DIR/termux/picoclaw-wrapper"

ARCHIVE_PATH="$OUTPUT_DIR/$ASSET_NAME"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"
rm -f -- "$ARCHIVE_PATH" "$CHECKSUM_PATH"
(
  cd -- "$STAGE_DIR"
  TZ=UTC zip -X -r9 "$ARCHIVE_PATH" . >/dev/null
)

(
  cd -- "$OUTPUT_DIR"
  sha256sum "$ASSET_NAME" > "${ASSET_NAME}.sha256"
)

cat > "$OUTPUT_DIR/metadata.env" <<EOF
UPSTREAM_TAG=$UPSTREAM_TAG
MODULE_REVISION=$MODULE_REVISION
MODULE_VERSION=$MODULE_VERSION
VERSION_CODE=$VERSION_CODE
ASSET_NAME=$ASSET_NAME
ARCHIVE_PATH=$ARCHIVE_PATH
CHECKSUM_PATH=$CHECKSUM_PATH
EOF

printf 'Module:   %s\n' "$ARCHIVE_PATH"
printf 'SHA-256: %s\n' "$CHECKSUM_PATH"
