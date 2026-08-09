#!/system/bin/sh

MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
# shellcheck source=module/termux.sh
. "$MODDIR/termux.sh"

module_log 'Menyinkronkan wrapper Termux...'
install_termux_wrappers || true

if launcher_is_running; then
  launcher_stop
else
  launcher_start
fi
