#!/system/bin/sh

MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
# shellcheck source=module/termux.sh
. "$MODDIR/termux.sh"

write_setting() {
  write_key=$1
  write_value=$2
  ensure_data_dirs
  write_temp=$PICO_SETTINGS.tmp.$$
  awk -F= -v key="$write_key" '$1 != key { print }' "$PICO_SETTINGS" > "$write_temp"
  printf '%s=%s\n' "$write_key" "$write_value" >> "$write_temp"
  chmod 0600 "$write_temp" 2>/dev/null || true
  mv "$write_temp" "$PICO_SETTINGS"
}

show_status() {
  ensure_data_dirs
  status_running=0
  status_pid=
  if launcher_is_running; then
    status_running=1
    status_pid=$(launcher_pid)
  fi
  status_autostart=$(read_setting AUTOSTART 1)
  status_port=$(launcher_port)
  status_host=$(launcher_host)
  status_wrappers=$(termux_wrappers_status)
  status_version=$(sed -n 's/^version=//p' "$MODDIR/module.prop" | head -n 1)
  status_upstream=$(sed -n 's/^upstreamTag=//p' "$MODDIR/build-info.prop" 2>/dev/null | head -n 1)

  printf 'RUNNING=%s\n' "$status_running"
  printf 'PID=%s\n' "$status_pid"
  printf 'AUTOSTART=%s\n' "$status_autostart"
  printf 'HOST=%s\n' "$status_host"
  printf 'PORT=%s\n' "$status_port"
  printf 'URL=http://127.0.0.1:%s\n' "$status_port"
  printf 'WRAPPERS=%s\n' "$status_wrappers"
  printf 'VERSION=%s\n' "$status_version"
  printf 'UPSTREAM=%s\n' "$status_upstream"
  printf 'CONFIG=%s\n' "$PICO_CONFIG"
  printf 'LOG=%s\n' "$PICO_LOG"
}

usage() {
  printf '%s\n' 'Usage: picoclaw-ctl {status|start|stop|restart|toggle|autostart|wrappers|logs|url}'
  printf '%s\n' '  autostart on|off'
  printf '%s\n' '  wrappers install|remove|status'
  printf '%s\n' '  logs [jumlah-baris]'
}

control_command=${1:-status}
case "$control_command" in
  status)
    show_status
    ;;
  start)
    launcher_start
    ;;
  stop)
    launcher_stop
    ;;
  restart)
    launcher_restart
    ;;
  toggle)
    if launcher_is_running; then
      launcher_stop
    else
      launcher_start
    fi
    ;;
  autostart)
    case "${2:-}" in
      on|1|enable|enabled)
        write_setting AUTOSTART 1
        module_log 'Autostart diaktifkan.'
        ;;
      off|0|disable|disabled)
        write_setting AUTOSTART 0
        module_log 'Autostart dinonaktifkan.'
        ;;
      *)
        printf '%s\n' "$(read_setting AUTOSTART 1)"
        ;;
    esac
    ;;
  wrappers)
    case "${2:-status}" in
      install) install_termux_wrappers ;;
      remove) remove_termux_wrappers ;;
      status) termux_wrappers_status ;;
      *) usage >&2; exit 2 ;;
    esac
    ;;
  logs)
    log_lines=${2:-120}
    case "$log_lines" in
      ''|*[!0-9]*) log_lines=120 ;;
      *)
        if [ "$log_lines" -lt 1 ] || [ "$log_lines" -gt 500 ]; then
          log_lines=120
        fi
        ;;
    esac
    if [ -f "$PICO_LOG" ]; then
      tail -n "$log_lines" "$PICO_LOG"
    else
      printf 'Log belum tersedia.\n'
    fi
    ;;
  url)
    printf 'http://127.0.0.1:%s\n' "$(launcher_port)"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
