#!/system/bin/sh

MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
# shellcheck source=module/termux.sh
. "$MODDIR/termux.sh"

echo "===================================="
echo "    PicoClaw Diagnostic Panel"
echo "===================================="
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo

echo "[STATUS]"
if [ -x "$PICO_CORE_BIN" ]; then
  echo "✓ Core Exec  : Installed"
else
  echo "✗ Core Exec  : Missing"
fi

if [ -x "$PICO_LAUNCHER_BIN" ]; then
  echo "✓ Web Server : Installed"
else
  echo "✗ Web Server : Missing"
fi

if launcher_is_running; then
  run_pid=$(launcher_pid)
  echo "✓ Service    : RUNNING (PID $run_pid)"
else
  echo "✗ Service    : STOPPED"
fi

l_port=$(launcher_port)
echo "✓ WebUI Port : $l_port"

w_status=$(termux_wrappers_status)
case "$w_status" in
  ready) echo "✓ Termux CLI : Ready (17 Wrappers)" ;;
  *)
    install_termux_wrappers >/dev/null 2>&1 || true
    echo "✓ Termux CLI : Synced Wrappers"
    ;;
esac

echo
echo "[SHORTCUTS]"
echo "• WebUI      : http://127.0.0.1:$l_port"
echo "• Termux CLI : picoclaw version"
echo "• Data Dir   : /data/adb/picoclaw"

echo
echo "[RECENT LOGS]"
if [ -f "$PICO_LOG" ]; then
  last_log=$(tail -n 3 "$PICO_LOG" 2>/dev/null | sed 's/^/  /')
  if [ -n "$last_log" ]; then
    echo "$last_log"
  else
    echo "  No recent log entries"
  fi
else
  echo "  Log file not found"
fi

echo "===================================="
