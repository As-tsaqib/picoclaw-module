#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

mapfile -t SHELL_FILES < <(
  find "$REPO_DIR/scripts" "$REPO_DIR/module" -type f \
    \( -name '*.sh' -o -name 'picoclaw-wrapper' \) -print | sort
)

for script in "${SHELL_FILES[@]}"; do
  bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x -s bash "$REPO_DIR"/scripts/*.sh
  shellcheck -x -s sh \
    "$REPO_DIR"/module/*.sh \
    "$REPO_DIR"/module/termux/picoclaw-wrapper
fi

if command -v node >/dev/null 2>&1; then
  node --check "$REPO_DIR/module/webroot/app.js"
  node --check "$REPO_DIR/module/webroot/kernelsu.js"
fi

grep -q '^id=picoclaw$' "$REPO_DIR/module/module.prop"
grep -q '^updateJson=https://raw.githubusercontent.com/As-tsaqib/picoclaw-module/main/update.json$' \
  "$REPO_DIR/module/module.prop"
grep -q 'PICOCLAW_MODULE_WRAPPER=1' "$REPO_DIR/module/termux/picoclaw-wrapper"
[[ -f $REPO_DIR/module/skip_mount ]]
[[ ! -d $REPO_DIR/module/system ]]

EXPECTED_SUBCOMMANDS=(
  config onboard agent auth gateway status cron mcp migrate skills model update version
)
for subcommand in "${EXPECTED_SUBCOMMANDS[@]}"; do
  grep -qw "picoclaw-$subcommand" "$REPO_DIR/module/termux.sh"
  grep -qw "picoclaw-$subcommand" "$REPO_DIR/module/termux/picoclaw-wrapper"
done

TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/picoclaw-module-test.XXXXXX")"
cleanup() {
  rm -rf -- "$TEST_DIR"
}
trap cleanup EXIT

mkdir -p "$TEST_DIR/source/build" "$TEST_DIR/dist"
printf 'MIT test license\n' > "$TEST_DIR/source/LICENSE"
printf '#!/system/bin/sh\nexit 0\n' > "$TEST_DIR/source/build/picoclaw-android-arm64"
printf '#!/system/bin/sh\nexit 0\n' > "$TEST_DIR/source/build/picoclaw-launcher-android-arm64"
chmod 0755 \
  "$TEST_DIR/source/build/picoclaw-android-arm64" \
  "$TEST_DIR/source/build/picoclaw-launcher-android-arm64"

PICOCLAW_SKIP_ELF_CHECK=1 \
  "$SCRIPT_DIR/package-module.sh" "$TEST_DIR/source" v0.3.1 "$TEST_DIR/dist" >/dev/null

TEST_REVISION="$(tr -d '[:space:]' < "$REPO_DIR/MODULE_REVISION")"
TEST_VERSION="v0.3.1-r${TEST_REVISION}"
TEST_VERSION_CODE=$((300100 + 10#$TEST_REVISION))
ARCHIVE="$TEST_DIR/dist/PicoClaw-Module-${TEST_VERSION}-arm64.zip"
[[ -f $ARCHIVE ]]
[[ -f $ARCHIVE.sha256 ]]
(
  cd "$TEST_DIR/dist"
  sha256sum -c "$(basename "$ARCHIVE").sha256" >/dev/null
)

unzip -Z1 "$ARCHIVE" | grep -qx 'module.prop'
unzip -Z1 "$ARCHIVE" | grep -qx 'bin/picoclaw'
unzip -Z1 "$ARCHIVE" | grep -qx 'bin/picoclaw-launcher'
unzip -Z1 "$ARCHIVE" | grep -qx 'webroot/index.html'
unzip -p "$ARCHIVE" module.prop | grep -qx "version=$TEST_VERSION"
unzip -p "$ARCHIVE" module.prop | grep -qx "versionCode=$TEST_VERSION_CODE"
if unzip -p "$ARCHIVE" module.prop | grep -q '@[A-Z_]\+@'; then
  printf 'Placeholder module.prop masih tersisa di archive.\n' >&2
  exit 1
fi

mkdir -p "$TEST_DIR/unpacked"
unzip -q "$ARCHIVE" -d "$TEST_DIR/unpacked"
[[ -x $TEST_DIR/unpacked/bin/picoclaw ]]
[[ -x $TEST_DIR/unpacked/bin/picoclaw-launcher ]]
[[ -x $TEST_DIR/unpacked/service.sh ]]

"$SCRIPT_DIR/write-update-json.sh" \
  "$TEST_VERSION" \
  "$TEST_VERSION_CODE" \
  https://example.com/module.zip \
  https://example.com/changelog \
  "$TEST_DIR/update.json"
jq -e \
  --arg version "$TEST_VERSION" \
  --argjson versionCode "$TEST_VERSION_CODE" \
  '.version == $version and .versionCode == $versionCode and .zipUrl == "https://example.com/module.zip"' \
  "$TEST_DIR/update.json" >/dev/null

printf 'Semua pemeriksaan lulus.\n'
