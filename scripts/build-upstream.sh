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

require_command git
require_command go
require_command make
require_command node
require_command pnpm
require_command zip
require_command file

[[ -f $SOURCE_DIR/go.mod ]] || die "go.mod upstream tidak ditemukan di $SOURCE_DIR"
grep -qx 'module github.com/sipeed/picoclaw' "$SOURCE_DIR/go.mod" ||
  die "SOURCE_DIR bukan source tree sipeed/picoclaw"

head_commit="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
tag_commit="$(git -C "$SOURCE_DIR" rev-parse "${UPSTREAM_TAG}^{commit}")"
[[ $head_commit == "$tag_commit" ]] ||
  die "HEAD source ($head_commit) bukan commit tag $UPSTREAM_TAG ($tag_commit)"

printf 'Building PicoClaw %s for android/arm64...\n' "$UPSTREAM_TAG"
CGO_ENABLED=0 make -C "$SOURCE_DIR" VERSION="$UPSTREAM_TAG" build-android-bundle

"$SCRIPT_DIR/package-module.sh" "$SOURCE_DIR" "$UPSTREAM_TAG" "$OUTPUT_DIR"
