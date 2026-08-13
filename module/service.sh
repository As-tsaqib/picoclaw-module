#!/system/bin/sh

MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"

ensure_data_dirs

# Wait for Android boot completion (max 60 seconds)
boot_wait=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$boot_wait" -lt 30 ]; do
  sleep 2
  boot_wait=$((boot_wait + 1))
done
sleep 3

rm -f "$PICO_MANUAL_STOP" 2>/dev/null || true

if [ "$(read_setting AUTOSTART 1)" = 1 ]; then
  launcher_start >> "$PICO_LOG" 2>&1
fi

# Background Watchdog Daemon
while true; do
  sleep 30
  if [ "$(read_setting AUTOSTART 1)" = 1 ] && [ ! -f "$PICO_MANUAL_STOP" ]; then
    launcher_watchdog_start >> "$PICO_LOG" 2>&1 || true
  fi
done
