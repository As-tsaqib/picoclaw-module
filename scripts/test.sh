#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

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
  if [[ -f "$REPO_DIR/module/webroot/app.js" ]]; then
    node --check "$REPO_DIR/module/webroot/app.js"
  fi
  if [[ -f "$REPO_DIR/module/webroot/kernelsu.js" ]]; then
    node --check "$REPO_DIR/module/webroot/kernelsu.js"
  fi
fi

grep -q '^id=picoclaw$' "$REPO_DIR/module/module.prop"
grep -q '^updateJson=https://raw.githubusercontent.com/As-tsaqib/picoclaw-module/main/update.json$' \
  "$REPO_DIR/module/module.prop"
grep -q 'PICOCLAW_MODULE_WRAPPER=1' "$REPO_DIR/module/termux/picoclaw-wrapper"
[[ -f $REPO_DIR/module/skip_mount ]]
[[ ! -d $REPO_DIR/module/system ]]
grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' \
  "$REPO_DIR/MODULE_VERSION"
TEST_MODULE_VERSION="$(tr -d '[:space:]' < "$REPO_DIR/MODULE_VERSION")"
validate_module_version "$TEST_MODULE_VERSION"
TEST_SOURCE_REF="$(tr -d '[:space:]' < "$REPO_DIR/SOURCE_REF")"
validate_source_ref "$TEST_SOURCE_REF"
TEST_BUILT_SOURCE_REF="$(tr -d '[:space:]' < "$REPO_DIR/BUILT_SOURCE_REF")"
validate_source_ref "$TEST_BUILT_SOURCE_REF"
grep -Fq "PICOCLAW_FORK_URL='https://github.com/As-tsaqib/picoclaw'" \
  "$REPO_DIR/scripts/lib.sh"
grep -Fq "export PICOCLAW_FORK_MODULE_PATH='github.com/As-tsaqib/picoclaw'" \
  "$REPO_DIR/scripts/lib.sh"
# The expression below is a literal workflow-source assertion.
# shellcheck disable=SC2016
grep -Fq 'source_ref="$(tr -d '\''[:space:]'\'' < SOURCE_REF)"' \
  "$REPO_DIR/.github/workflows/build-fork.yml"
# The dollar expressions below are literal source-code assertions.
# shellcheck disable=SC2016
grep -Fq 'require_fork_source_tree "$SOURCE_DIR"' \
  "$REPO_DIR/scripts/build-fork.sh"
# shellcheck disable=SC2016
grep -Fq 'require_fork_source_tree "$SOURCE_DIR"' \
  "$REPO_DIR/scripts/package-module.sh"
if grep -Fqi 'sipeed' "$REPO_DIR/.github/workflows/build-fork.yml"; then
  printf 'Workflow tidak boleh mengambil source/release dari sipeed/picoclaw.\n' >&2
  exit 1
fi
grep -Fq "CGO_ENABLED=1 CC=\"\$android_cc_path\"" "$REPO_DIR/scripts/build-fork.sh"
# The dollar expressions below are literal source-code assertions.
# shellcheck disable=SC2016
grep -Fq 'VERSION="$binary_version"' "$REPO_DIR/scripts/build-fork.sh"
# shellcheck disable=SC2016
grep -Fq 'PICOCLAW_SOURCE_REPOSITORY_URL="$source_repository_url"' \
  "$REPO_DIR/scripts/build-fork.sh"
# The dollar expression below is a literal source-code assertion.
# shellcheck disable=SC2016
grep -Fq 'grep -qx "module $PICOCLAW_FORK_MODULE_PATH" "$SOURCE_DIR/go.mod"' \
  "$REPO_DIR/scripts/build-fork.sh"
# shellcheck disable=SC2016
grep -Fq 'git -C "$SOURCE_DIR" status --porcelain' \
  "$REPO_DIR/scripts/build-fork.sh"
# shellcheck disable=SC2016
grep -Fq 'git -C "$SOURCE_DIR" worktree add --detach "$BUILD_SOURCE_DIR" "$head_commit"' \
  "$REPO_DIR/scripts/build-fork.sh"
grep -Fq 'PICOCLAW_WEBUI_OUT_DIR' "$REPO_DIR/webui/vite.config.js"
[[ -x $REPO_DIR/scripts/check-webui.sh ]]
grep -Fq $'build\\tCGO_ENABLED=1' "$REPO_DIR/scripts/package-module.sh"
grep -Fq 'github.com\/As-tsaqib\/picoclaw\/pkg\/config\.Version=' \
  "$REPO_DIR/scripts/package-module.sh"
if grep -Fq 'github.com\/sipeed\/picoclaw\/pkg\/config\.Version=' \
  "$REPO_DIR/scripts/package-module.sh"; then
  printf 'Parser metadata binary tidak boleh memakai module path lama.\n' >&2
  exit 1
fi
# shellcheck disable=SC2016
grep -Fq 'sourceRepo=$source_repository_url' "$REPO_DIR/scripts/package-module.sh"
grep -Eq '^[0-9a-f]{40}$' "$REPO_DIR/BUILT_SOURCE_COMMIT"
grep -Fq '//go:build android || ((darwin || freebsd) && !cgo)' \
  "$REPO_DIR/patches/android-cgo-systray.patch"
if grep -Fq 'CGO_ENABLED=0 make' "$REPO_DIR/scripts/build-fork.sh"; then
  printf 'Build Android tidak boleh menonaktifkan cgo karena akan merusak DNS Android.\n' >&2
  exit 1
fi

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
git -C "$TEST_DIR/source" init -q
git -C "$TEST_DIR/source" config user.name 'PicoClaw module test'
git -C "$TEST_DIR/source" config user.email 'picoclaw-module-test@example.invalid'
git -C "$TEST_DIR/source" add .
git -C "$TEST_DIR/source" commit -q -m 'test: fake fork source'
git -C "$TEST_DIR/source" remote add origin https://github.com/As-tsaqib/picoclaw.git
TEST_SOURCE_COMMIT="$(git -C "$TEST_DIR/source" rev-parse HEAD)"
TEST_PACKAGE_SOURCE_REF='test-ref'

if PICOCLAW_SKIP_ELF_CHECK=1 \
  bash "$SCRIPT_DIR/package-module.sh" "$TEST_DIR/source" "$TEST_PACKAGE_SOURCE_REF" "$TEST_DIR/dist" \
  "$TEST_SOURCE_COMMIT" test-binary >/dev/null 2>&1; then
  :
else
  printf 'Checkout fork valid ditolak oleh package-module.sh.\n' >&2
  exit 1
fi

git -C "$TEST_DIR/source" remote set-url origin https://github.com/sipeed/picoclaw.git
if PICOCLAW_SKIP_ELF_CHECK=1 \
  bash "$SCRIPT_DIR/package-module.sh" "$TEST_DIR/source" "$TEST_PACKAGE_SOURCE_REF" "$TEST_DIR/dist" \
  "$TEST_SOURCE_COMMIT" test-binary >/dev/null 2>&1; then
  printf 'Checkout sipeed/picoclaw tidak boleh diterima oleh package-module.sh.\n' >&2
  exit 1
fi
git -C "$TEST_DIR/source" remote set-url origin https://github.com/As-tsaqib/picoclaw.git

PICOCLAW_SKIP_ELF_CHECK=1 \
PICOCLAW_BINARY_VERSION=test-binary \
  bash "$SCRIPT_DIR/package-module.sh" "$TEST_DIR/source" "$TEST_PACKAGE_SOURCE_REF" "$TEST_DIR/dist" \
  "$TEST_SOURCE_COMMIT" test-binary >/dev/null

TEST_VERSION="$(tr -d '[:space:]' < "$REPO_DIR/MODULE_VERSION")"
TEST_VERSION_CODE="$(module_version_code "$TEST_VERSION")"
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
unzip -p "$ARCHIVE" build-info.prop | grep -qx 'customSource=1'
unzip -p "$ARCHIVE" build-info.prop | grep -qx \
  'sourceRepo=https://github.com/As-tsaqib/picoclaw'
unzip -p "$ARCHIVE" build-info.prop | grep -qx "sourceRef=$TEST_PACKAGE_SOURCE_REF"
unzip -p "$ARCHIVE" build-info.prop | grep -qx "sourceCommit=$TEST_SOURCE_COMMIT"
unzip -p "$ARCHIVE" build-info.prop | grep -qx 'binaryVersion=test-binary'
unzip -p "$ARCHIVE" build-info.prop | grep -qx "moduleVersion=$TEST_VERSION"
if unzip -p "$ARCHIVE" module.prop | grep -q '@[A-Z_]\+@'; then
  printf 'Placeholder module.prop masih tersisa di archive.\n' >&2
  exit 1
fi

mkdir -p "$TEST_DIR/unpacked"
unzip -q "$ARCHIVE" -d "$TEST_DIR/unpacked"
[[ -x $TEST_DIR/unpacked/bin/picoclaw ]]
[[ -x $TEST_DIR/unpacked/bin/picoclaw-launcher ]]
[[ -x $TEST_DIR/unpacked/service.sh ]]

# Exercise the root control path with an isolated data directory. This covers
# credential files, archive allowlisting, and restore atomicity without touching
# a real Android /data tree.
CONTROL_DATA_DIR="$TEST_DIR/control-data"
mkdir -p "$CONTROL_DATA_DIR/workspace" "$CONTROL_DATA_DIR/.ssh"
printf 'original-config\n' > "$CONTROL_DATA_DIR/config.json"
printf 'api-secret\n' > "$CONTROL_DATA_DIR/.security.yml"
printf 'oauth-token\n' > "$CONTROL_DATA_DIR/auth.json"
printf 'launcher-password-hash\n' > "$CONTROL_DATA_DIR/launcher-config.json"
printf 'sqlite-auth\n' > "$CONTROL_DATA_DIR/launcher-auth.db"
printf 'private-key\n' > "$CONTROL_DATA_DIR/.ssh/picoclaw_ed25519.key"
printf 'public-key\n' > "$CONTROL_DATA_DIR/.ssh/picoclaw_ed25519.key.pub"
printf 'workspace-note\n' > "$CONTROL_DATA_DIR/workspace/note.txt"

CONTROL_MODULE_DIR="$TEST_DIR/control-module"
mkdir -p "$CONTROL_MODULE_DIR"
cp "$REPO_DIR/module/control.sh" "$CONTROL_MODULE_DIR/control.sh"
cp "$REPO_DIR/module/termux.sh" "$CONTROL_MODULE_DIR/termux.sh"
sed "s|PICO_DATA_DIR=/data/adb/picoclaw|PICO_DATA_DIR=$CONTROL_DATA_DIR|" \
  "$REPO_DIR/module/common.sh" > "$CONTROL_MODULE_DIR/common.sh"
chmod 0755 "$CONTROL_MODULE_DIR/control.sh" "$CONTROL_MODULE_DIR/common.sh" "$CONTROL_MODULE_DIR/termux.sh"

cat > "$CONTROL_MODULE_DIR/module.prop" <<'EOF'
version=@TEST_VERSION@
EOF
sed -i "s/@TEST_VERSION@/$TEST_VERSION/" "$CONTROL_MODULE_DIR/module.prop"
cat > "$CONTROL_MODULE_DIR/build-info.prop" <<EOF
sourceRef=$TEST_PACKAGE_SOURCE_REF
sourceCommit=0123456789012345678901234567890123456789
binaryVersion=test-binary
EOF
CONTROL_STATUS="$(sh "$CONTROL_MODULE_DIR/control.sh" status)"
grep -Fxq "MODULE_VERSION=$TEST_VERSION" <<< "$CONTROL_STATUS"
grep -Fxq 'BINARY_VERSION=test-binary' <<< "$CONTROL_STATUS"

mkdir -p "$CONTROL_DATA_DIR/run/launcher.lock"
printf 'not-a-pid\n' > "$CONTROL_DATA_DIR/run/launcher.lock/pid"
printf 'stale-test\n' > "$CONTROL_DATA_DIR/run/launcher.lock/operation"
sh "$CONTROL_MODULE_DIR/control.sh" backup "$TEST_DIR/control-backup.tar.gz" >/dev/null
[[ ! -d $CONTROL_DATA_DIR/run/launcher.lock ]]
for backup_entry in \
  config.json .security.yml auth.json launcher-config.json launcher-auth.db \
  .ssh/picoclaw_ed25519.key .ssh/picoclaw_ed25519.key.pub workspace/note.txt; do
  tar -tzf "$TEST_DIR/control-backup.tar.gz" | grep -Fxq "$backup_entry"
done

printf 'changed-config\n' > "$CONTROL_DATA_DIR/config.json"
sh "$CONTROL_MODULE_DIR/control.sh" restore \
  "$TEST_DIR/control-backup.tar.gz" >/dev/null
grep -Fxq 'original-config' "$CONTROL_DATA_DIR/config.json"
grep -Fxq 'api-secret' "$CONTROL_DATA_DIR/.security.yml"
[[ $(stat -c '%a' "$CONTROL_DATA_DIR/launcher-auth.db") == 600 ]]

mkdir -p "$TEST_DIR/unsafe-payload/config.json"
tar -czf "$TEST_DIR/unsafe-type.tar.gz" -C "$TEST_DIR/unsafe-payload" config.json
if sh "$CONTROL_MODULE_DIR/control.sh" restore \
  "$TEST_DIR/unsafe-type.tar.gz" >/dev/null 2>&1; then
  printf 'Archive dengan tipe entry tidak valid diterima.\n' >&2
  exit 1
fi
grep -Fxq 'original-config' "$CONTROL_DATA_DIR/config.json"

bash "$SCRIPT_DIR/write-update-json.sh" \
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
