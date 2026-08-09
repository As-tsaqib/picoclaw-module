#!/system/bin/sh

MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
# shellcheck source=module/termux.sh
. "$MODDIR/termux.sh"

launcher_stop || true
remove_termux_wrappers || true
module_log 'Data /data/adb/picoclaw dipertahankan agar config dan credential tidak hilang.'
