#!/system/bin/sh

MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"

ensure_data_dirs
sleep 10

if [ "$(read_setting AUTOSTART 1)" = 1 ]; then
  launcher_start >> "$PICO_LOG" 2>&1
fi
