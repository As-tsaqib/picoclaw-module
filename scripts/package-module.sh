#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

SOURCE_DIR=${1:-}
SOURCE_REF_INPUT=${2:-main}
OUTPUT_DIR=${3:-"$REPO_DIR/dist"}
SOURCE_COMMIT_INPUT=${4:-${PICOCLAW_SOURCE_COMMIT:-}}
BINARY_VERSION_INPUT=${5:-${PICOCLAW_BINARY_VERSION:-}}

[[ -n $SOURCE_DIR ]] || {
  printf 'Usage: %s SOURCE_DIR [SOURCE_REF] [OUTPUT_DIR] [SOURCE_COMMIT] [BINARY_VERSION]\n' "$0" >&2
  exit 2
}

load_module_metadata
validate_source_ref "$SOURCE_REF_INPUT"
SOURCE_DIR="$(cd -- "$SOURCE_DIR" && pwd)"
mkdir -p -- "$OUTPUT_DIR"
OUTPUT_DIR="$(cd -- "$OUTPUT_DIR" && pwd)"
require_fork_source_tree "$SOURCE_DIR"

CORE_SOURCE="$SOURCE_DIR/build/picoclaw-android-arm64"
LAUNCHER_SOURCE="$SOURCE_DIR/build/picoclaw-launcher-android-arm64"
source_repository_url="${PICOCLAW_SOURCE_REPOSITORY_URL:-$PICOCLAW_FORK_URL}"
validate_source_repository_url "$source_repository_url"
source_repository_url=$PICOCLAW_FORK_URL

source_commit=unknown
if git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  source_commit="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
fi
if [[ -n $SOURCE_COMMIT_INPUT && $source_commit != "$SOURCE_COMMIT_INPUT" ]]; then
  die "commit source package ($source_commit) tidak sesuai ($SOURCE_COMMIT_INPUT)"
fi

binary_version=$BINARY_VERSION_INPUT
[[ -n $binary_version && $binary_version != *[[:space:]]* ]] || binary_version=unknown

[[ -x $CORE_SOURCE ]] || die "binary core fork tidak ditemukan/executable: $CORE_SOURCE"
[[ -x $LAUNCHER_SOURCE ]] || die "binary launcher fork tidak ditemukan/executable: $LAUNCHER_SOURCE"
[[ -f $SOURCE_DIR/LICENSE ]] || die "LICENSE PicoClaw fork tidak ditemukan"

validate_elf_arm64() {
  local binary=$1
  local build_metadata description observed_binary_version

  if [[ ${PICOCLAW_SKIP_ELF_CHECK:-0} == 1 ]]; then
    return 0
  fi

  require_command file
  description="$(file -b -- "$binary")"
  [[ $description == *ELF\ 64-bit* && $description == *ARM\ aarch64* ]] ||
    die "$binary bukan ELF Android ARM64: $description"

  require_command go
  build_metadata="$(go version -m "$binary")"
  observed_binary_version="$(sed -n \
    's/.*github.com\/sipeed\/picoclaw\/pkg\/config\.Version=\([^"[:space:]]*\).*/\1/p' \
    <<< "$build_metadata" | head -n 1)"
  [[ -n $observed_binary_version ]] ||
    die "$binary tidak memuat metadata versi binary"
  if [[ $binary_version == unknown ]]; then
    binary_version=$observed_binary_version
  fi
  [[ $observed_binary_version == "$binary_version" ]] ||
    die "$binary memuat versi binary $observed_binary_version, yang diharapkan $binary_version"
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
  "$STAGE_DIR/module.prop"

cat > "$STAGE_DIR/build-info.prop" <<EOF
sourceRepo=$source_repository_url
sourceRef=$SOURCE_REF_INPUT
sourceCommit=$source_commit
customSource=1
binaryVersion=$binary_version
moduleVersion=$MODULE_VERSION
moduleVersionCode=$VERSION_CODE
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
MODULE_VERSION=$MODULE_VERSION
VERSION_CODE=$VERSION_CODE
ASSET_NAME=$ASSET_NAME
ARCHIVE_PATH=$ARCHIVE_PATH
CHECKSUM_PATH=$CHECKSUM_PATH
SOURCE_REPOSITORY=$source_repository_url
SOURCE_REF=$SOURCE_REF_INPUT
SOURCE_COMMIT=$source_commit
BINARY_VERSION=$binary_version
EOF

printf 'Module:   %s\n' "$ARCHIVE_PATH"
printf 'SHA-256: %s\n' "$CHECKSUM_PATH"
