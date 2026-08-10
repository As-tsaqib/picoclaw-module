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
  printf '%s\n' 'Usage: picoclaw-ctl {status|start|stop|restart|toggle|autostart|port|backup|restore|wrappers|logs|url}'
  printf '%s\n' '  autostart on|off'
  printf '%s\n' '  port [nomor-port]'
  printf '%s\n' '  backup [file-tujuan.tar.gz]'
  printf '%s\n' '  restore <file-sumber.tar.gz>'
  printf '%s\n' '  wrappers install|remove|status'
  printf '%s\n' '  logs [jumlah-baris|clear]'
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
  port)
    if [ -n "${2:-}" ]; then
      new_port=$2
      case "$new_port" in
        ''|*[!0-9]*)
          module_log 'Port harus berupa angka antara 1 dan 65535.' >&2
          exit 1
          ;;
        *)
          if [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
            module_log 'Port harus berada pada rentang 1..65535.' >&2
            exit 1
          fi
          ;;
      esac
      write_setting PORT "$new_port"
      if launcher_is_running; then
        launcher_restart
      fi
      module_log "Port berhasil diubah ke $new_port."
    else
      launcher_port
    fi
    ;;
  backup)
    dest_file=${2:-}
    if [ -z "$dest_file" ]; then
      timestamp=$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo "latest")
      if [ -d "/sdcard/Download" ]; then
        dest_file="/sdcard/Download/picoclaw-backup-${timestamp}.tar.gz"
      elif [ -d "/sdcard" ]; then
        dest_file="/sdcard/picoclaw-backup-${timestamp}.tar.gz"
      else
        dest_file="$PICO_DATA_DIR/picoclaw-backup-${timestamp}.tar.gz"
      fi
    fi
    ensure_data_dirs
    dest_dir=$(dirname "$dest_file")
    mkdir -p "$dest_dir" 2>/dev/null || true

    (
      cd "$PICO_DATA_DIR" || exit 1
      tar -czf "$dest_file" \
        config.json settings.conf workspace \
        2>/dev/null || tar -czf "$dest_file" config.json settings.conf 2>/dev/null
    )
    if [ -f "$dest_file" ]; then
      module_log "Backup berhasil disimpan ke $dest_file"
    else
      module_log "Gagal membuat backup." >&2
      exit 1
    fi
    ;;
  restore)
    src_file=${2:-}
    if [ -z "$src_file" ] || [ ! -f "$src_file" ]; then
      module_log "File backup tidak ditemukan: ${src_file:-<kosong>}" >&2
      exit 1
    fi
    was_running=0
    if launcher_is_running; then
      was_running=1
      launcher_stop
    fi
    ensure_data_dirs
    if tar -tzf "$src_file" >/dev/null 2>&1; then
      tar -xzf "$src_file" -C "$PICO_DATA_DIR" 2>/dev/null
      ensure_data_dirs
      module_log "Restore berhasil dari $src_file"
      if [ "$was_running" = 1 ]; then
        launcher_start
      fi
    else
      module_log "File backup merusak atau format tidak valid." >&2
      exit 1
    fi
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
    case "${2:-}" in
      clear|clean)
        if [ -f "$PICO_LOG" ]; then
          : > "$PICO_LOG"
          module_log 'Log berhasil dibersihkan.'
        else
          module_log 'Log belum ada.'
        fi
        ;;
      *)
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
    esac
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

