#!/system/bin/sh

MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
# shellcheck source=module/termux.sh
. "$MODDIR/termux.sh"

write_setting_unlocked() {
  write_key=$1
  write_value=$2
  ensure_data_dirs
  write_temp=$PICO_SETTINGS.tmp.$$
  awk -F= -v key="$write_key" '$1 != key { print }' "$PICO_SETTINGS" > "$write_temp"
  printf '%s=%s\n' "$write_key" "$write_value" >> "$write_temp"
  chmod 0600 "$write_temp" 2>/dev/null || true
  mv "$write_temp" "$PICO_SETTINGS"
}

write_setting() {
  if ! launcher_lock_acquire setting; then
    return 1
  fi
  write_setting_unlocked "$1" "$2"
  write_result=$?
  launcher_lock_release
  return "$write_result"
}

backup_entry_allowed() {
  backup_entry=$1
  while [ "${backup_entry#./}" != "$backup_entry" ]; do
    backup_entry=${backup_entry#./}
  done
  while [ -n "$backup_entry" ] && [ "${backup_entry%/}" != "$backup_entry" ]; do
    backup_entry=${backup_entry%/}
  done

  case "$backup_entry" in
    ''|/*|../*|*/../*|*/..|..|*//* ) return 1 ;;
  esac
  case "$backup_entry" in
    config.json|settings.conf|.security.yml|auth.json|launcher-config.json|launcher-auth.db)
      return 0
      ;;
    .ssh|.ssh/picoclaw_ed25519.key|.ssh/picoclaw_ed25519.key.pub)
      return 0
      ;;
    workspace|workspace/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

validate_backup_archive() {
  validate_archive=$1
  validate_list="$PICO_TMP_DIR/backup-list.$$"
  validate_verbose="$PICO_TMP_DIR/backup-verbose.$$"
  validate_count=0

  if ! tar -tzf "$validate_archive" > "$validate_list" 2>/dev/null; then
    rm -f "$validate_list" "$validate_verbose" 2>/dev/null || true
    module_log 'File backup tidak dapat dibaca sebagai gzip tar.' >&2
    return 1
  fi

  validate_error=0
  while IFS= read -r validate_entry || [ -n "$validate_entry" ]; do
    if ! backup_entry_allowed "$validate_entry"; then
      module_log "Entry backup ditolak: $validate_entry" >&2
      validate_error=1
      break
    fi
    validate_count=$((validate_count + 1))
  done < "$validate_list"
  if [ "$validate_error" -ne 0 ]; then
    rm -f "$validate_list" "$validate_verbose" 2>/dev/null || true
    return 1
  fi

  if [ "$validate_count" -eq 0 ] ||
    ! tar -tvzf "$validate_archive" > "$validate_verbose" 2>/dev/null; then
    rm -f "$validate_list" "$validate_verbose" 2>/dev/null || true
    module_log 'Backup kosong atau metadata archive tidak valid.' >&2
    return 1
  fi

  validate_error=0
  while IFS= read -r validate_line || [ -n "$validate_line" ]; do
    validate_type=${validate_line%"${validate_line#?}"}
    case "$validate_type" in
      -|d) ;;
      *)
        module_log 'Backup mengandung symlink, hardlink, atau file khusus; restore dibatalkan.' >&2
        validate_error=1
        break
        ;;
    esac
  done < "$validate_verbose"

  rm -f "$validate_list" "$validate_verbose" 2>/dev/null || true
  [ "$validate_error" -eq 0 ]
}

backup_create() {
  backup_destination=$1
  ensure_data_dirs

  case "$backup_destination" in
    /*) ;;
    *) backup_destination="$(pwd)/$backup_destination" ;;
  esac

  if [ -L "$backup_destination" ]; then
    module_log "Tujuan backup adalah symlink dan ditolak: $backup_destination" >&2
    return 1
  fi
  if [ -d "$backup_destination" ]; then
    module_log "Tujuan backup harus berupa nama file, bukan direktori: $backup_destination" >&2
    return 1
  fi
  backup_destination_dir=$(dirname "$backup_destination")
  if ! mkdir -p "$backup_destination_dir" 2>/dev/null; then
    module_log "Tidak dapat membuat direktori tujuan backup: $backup_destination_dir" >&2
    return 1
  fi

  backup_temp=$(mktemp "$backup_destination.tmp.XXXXXX" 2>/dev/null) || {
    module_log "Tidak dapat membuat file sementara backup: $backup_destination" >&2
    return 1
  }
  backup_tmp_dir=$(cd "$PICO_TMP_DIR" 2>/dev/null && pwd) || {
    rm -f "$backup_temp" 2>/dev/null || true
    module_log 'Tidak dapat menentukan direktori sementara backup.' >&2
    return 1
  }
  backup_items_file=$(mktemp "$backup_tmp_dir/backup-items.XXXXXX" 2>/dev/null) || {
    rm -f "$backup_temp" 2>/dev/null || true
    module_log 'Tidak dapat membuat daftar file backup sementara.' >&2
    return 1
  }
  backup_count=0
  for backup_item in \
    config.json settings.conf .security.yml auth.json \
    launcher-config.json launcher-auth.db .ssh/picoclaw_ed25519.key \
    .ssh/picoclaw_ed25519.key.pub workspace; do
    if path_exists_or_link "$PICO_DATA_DIR/$backup_item"; then
      if ! printf '%s\n' "$backup_item" >> "$backup_items_file"; then
        rm -f "$backup_temp" "$backup_items_file" 2>/dev/null || true
        module_log 'Tidak dapat menulis daftar file backup.' >&2
        return 1
      fi
      backup_count=$((backup_count + 1))
    fi
  done
  if [ "$backup_count" -eq 0 ]; then
    rm -f "$backup_items_file" 2>/dev/null || true
    module_log 'Tidak ada data PicoClaw yang dapat dibackup.' >&2
    return 1
  fi

  (
    cd "$PICO_DATA_DIR" || exit 1
    # The list contains only fixed allowlisted names.
    tar -czf "$backup_temp" -T "$backup_items_file"
  )
  backup_tar_result=$?
  rm -f "$backup_items_file" 2>/dev/null || true
  if [ "$backup_tar_result" -ne 0 ]; then
    rm -f "$backup_temp" 2>/dev/null || true
    module_log 'Gagal membuat backup.' >&2
    return 1
  fi
  if [ ! -s "$backup_temp" ]; then
    rm -f "$backup_temp" 2>/dev/null || true
    module_log 'Gagal membuat backup.' >&2
    return 1
  fi
  if ! validate_backup_archive "$backup_temp"; then
    rm -f "$backup_temp" 2>/dev/null || true
    module_log 'Backup mengandung entry yang tidak aman dan tidak disimpan.' >&2
    return 1
  fi
  chmod 0600 "$backup_temp" 2>/dev/null || true
  if ! mv -f "$backup_temp" "$backup_destination"; then
    rm -f "$backup_temp" 2>/dev/null || true
    module_log "Tidak dapat menyelesaikan backup ke $backup_destination" >&2
    return 1
  fi
  module_log "Backup berhasil disimpan ke $backup_destination"
  return 0
}

restore_cleanup() {
  rm -f "${restore_archive:-}" "${restore_journal:-}" 2>/dev/null || true
  rm -rf "${restore_stage:-}" "${restore_rollback:-}" 2>/dev/null || true
}

restore_rollback_data() {
  [ -f "$restore_journal" ] || return 0
  [ -n "$PICO_DATA_DIR" ] && [ "$PICO_DATA_DIR" != / ] || return 1
  while IFS=' ' read -r restore_had_previous restore_item ||
    [ -n "$restore_item" ]; do
    [ -n "$restore_item" ] || continue
    rm -rf -- "${PICO_DATA_DIR:?}/$restore_item" 2>/dev/null || true
    if [ "$restore_had_previous" = 1 ] &&
      path_exists_or_link "$restore_rollback/$restore_item"; then
      restore_parent=$(dirname "$PICO_DATA_DIR/$restore_item")
      mkdir -p "$restore_parent" 2>/dev/null || true
      mv "$restore_rollback/$restore_item" "$PICO_DATA_DIR/$restore_item" 2>/dev/null || true
    fi
  done < "$restore_journal"
}

restore_parent_is_safe() {
  restore_parent_path=$(dirname "$1")
  while [ "$restore_parent_path" != "$PICO_DATA_DIR" ] &&
    [ "$restore_parent_path" != / ]; do
    if [ -L "$restore_parent_path" ]; then
      return 1
    fi
    restore_parent_path=$(dirname "$restore_parent_path")
  done
  return 0
}

restore_entry_type_allowed() {
  restore_type_item=$1
  restore_type_path=$2
  [ ! -L "$restore_type_path" ] || return 1
  case "$restore_type_item" in
    workspace)
      [ -d "$restore_type_path" ]
      ;;
    .ssh/picoclaw_ed25519.key|.ssh/picoclaw_ed25519.key.pub)
      [ -f "$restore_type_path" ]
      ;;
    *)
      [ -f "$restore_type_path" ]
      ;;
  esac
}

restore_commit_data() {
  : > "$restore_journal" || return 1
  for restore_item in \
    config.json settings.conf .security.yml auth.json \
    launcher-config.json launcher-auth.db .ssh/picoclaw_ed25519.key \
    .ssh/picoclaw_ed25519.key.pub workspace; do
    restore_source="$restore_stage/$restore_item"
    if ! path_exists_or_link "$restore_source"; then
      continue
    fi
    if ! restore_entry_type_allowed "$restore_item" "$restore_source" ||
      ! restore_parent_is_safe "$PICO_DATA_DIR/$restore_item"; then
      return 1
    fi

    restore_had_previous=0
    if path_exists_or_link "$PICO_DATA_DIR/$restore_item"; then
      restore_had_previous=1
      restore_backup_parent=$(dirname "$restore_rollback/$restore_item")
      mkdir -p "$restore_backup_parent" || return 1
      mv "$PICO_DATA_DIR/$restore_item" "$restore_rollback/$restore_item" || return 1
    fi
    if ! printf '%s %s\n' "$restore_had_previous" "$restore_item" >> "$restore_journal"; then
      if [ "$restore_had_previous" = 1 ] &&
        path_exists_or_link "$restore_rollback/$restore_item"; then
        mv "$restore_rollback/$restore_item" "$PICO_DATA_DIR/$restore_item" 2>/dev/null || true
      fi
      return 1
    fi
    mkdir -p "$(dirname "$PICO_DATA_DIR/$restore_item")" || return 1
    mv "$restore_source" "$PICO_DATA_DIR/$restore_item" || return 1
  done
  return 0
}

restore_fix_permissions() {
  for restore_item in \
    config.json settings.conf .security.yml auth.json \
    launcher-config.json launcher-auth.db .ssh/picoclaw_ed25519.key \
    .ssh/picoclaw_ed25519.key.pub; do
    if [ -f "$PICO_DATA_DIR/$restore_item" ]; then
      chmod 0600 "$PICO_DATA_DIR/$restore_item" || return 1
    fi
  done
  if [ -d "$PICO_DATA_DIR/workspace" ]; then
    chmod 0700 "$PICO_DATA_DIR/workspace" || return 1
  fi
  return 0
}

backup_run() {
  if ! launcher_lock_acquire backup; then
    return 1
  fi

  backup_was_running=0
  if launcher_is_running; then
    backup_was_running=1
    if ! launcher_stop_unlocked; then
      module_log 'Launcher tidak dapat dihentikan; backup dibatalkan.' >&2
      launcher_lock_release
      return 1
    fi
  fi

  backup_create "$1"
  backup_result=$?
  if [ "$backup_was_running" = 1 ] && ! launcher_start_unlocked; then
    module_log 'Backup selesai, tetapi launcher gagal dimulai ulang.' >&2
    backup_result=1
  fi
  launcher_lock_release
  return "$backup_result"
}

restore_run() {
  restore_source_file=$1
  if [ -z "$restore_source_file" ] || [ ! -f "$restore_source_file" ] ||
    [ -L "$restore_source_file" ]; then
    module_log "File backup tidak ditemukan atau bukan file biasa: ${restore_source_file:-<kosong>}" >&2
    return 1
  fi
  ensure_data_dirs
  if ! launcher_lock_acquire restore; then
    return 1
  fi

  restore_archive=
  restore_stage=
  restore_rollback=
  restore_journal=
  if ! restore_archive=$(mktemp "$PICO_TMP_DIR/restore-archive.XXXXXX" 2>/dev/null) ||
    ! restore_stage=$(mktemp -d "$PICO_TMP_DIR/restore-stage.XXXXXX" 2>/dev/null) ||
    ! restore_rollback=$(mktemp -d "$PICO_TMP_DIR/restore-rollback.XXXXXX" 2>/dev/null) ||
    ! restore_journal=$(mktemp "$PICO_TMP_DIR/restore-journal.XXXXXX" 2>/dev/null); then
    module_log 'Tidak dapat membuat area restore sementara.' >&2
    restore_cleanup
    launcher_lock_release
    return 1
  fi

  if ! cp "$restore_source_file" "$restore_archive" 2>/dev/null ||
    ! chmod 0600 "$restore_archive" 2>/dev/null ||
    ! validate_backup_archive "$restore_archive" ||
    ! tar -xzf "$restore_archive" -C "$restore_stage" 2>/dev/null; then
    module_log 'File backup merusak, tidak aman, atau format tidak valid.' >&2
    restore_cleanup
    launcher_lock_release
    return 1
  fi

  restore_was_running=0
  if launcher_is_running; then
    restore_was_running=1
    if ! launcher_stop_unlocked; then
      module_log 'Launcher tidak dapat dihentikan; restore dibatalkan.' >&2
      restore_cleanup
      launcher_lock_release
      return 1
    fi
  fi

  if ! restore_commit_data; then
    restore_rollback_data
    if [ "$restore_was_running" = 1 ]; then
      launcher_start_unlocked >/dev/null 2>&1 ||
        module_log 'Restore gagal dan launcher lama juga tidak dapat dimulai ulang.' >&2
    fi
    module_log 'Restore dibatalkan; data lama dipertahankan.' >&2
    restore_cleanup
    launcher_lock_release
    return 1
  fi

  ensure_data_dirs
  if ! restore_fix_permissions; then
    module_log 'Restore berhasil tetapi permission data tidak dapat diamankan.' >&2
    restore_rollback_data
    if [ "$restore_was_running" = 1 ]; then
      launcher_start_unlocked >/dev/null 2>&1 || true
    fi
    restore_cleanup
    launcher_lock_release
    return 1
  fi
  if [ "$restore_was_running" = 1 ] && ! launcher_start_unlocked; then
    module_log 'Launcher gagal dimulai dengan data hasil restore; mengembalikan data lama.' >&2
    restore_rollback_data
    launcher_start_unlocked >/dev/null 2>&1 ||
      module_log 'Data lama dikembalikan, tetapi launcher lama gagal dimulai.' >&2
    restore_cleanup
    launcher_lock_release
    return 1
  fi

  restore_cleanup
  launcher_lock_release
  module_log "Restore berhasil dari $restore_source_file"
  return 0
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
  status_http=$(http_health_status)
  status_uptime=$(uptime_seconds)
  status_start_time=$(read_private_value "$PICO_ACTIVE_START_TIME_FILE")
  status_last_start_time=$(read_private_value "$PICO_LAST_START_TIME_FILE")
  status_watchdog=$(watchdog_health_status)
  status_last_restart_reason=$(last_restart_reason)
  status_last_restart_time=$(read_private_value "$PICO_LAST_RESTART_TIME_FILE")
  status_binary=$(binary_health_status)
  status_permission=$(permission_health_status)
  status_config=$(config_health_status)
  if listener_is_active "$status_port"; then
    status_listener=ok
  else
    status_listener=down
  fi
  case "$status_wrappers" in
    ready) status_wrapper_health=ready ;;
    *) status_wrapper_health=missing ;;
  esac
  status_module_version=$(sed -n 's/^version=//p' "$MODDIR/module.prop" | head -n 1)
  status_binary_version=$(sed -n 's/^binaryVersion=//p' "$MODDIR/build-info.prop" 2>/dev/null | head -n 1)
  if [ -z "$status_binary_version" ]; then
    # Compatibility with modules built before the independent version format.
    status_binary_version=$(sed -n 's/^upstreamTag=//p' "$MODDIR/build-info.prop" 2>/dev/null | head -n 1)
  fi
  status_source_ref=$(sed -n 's/^sourceRef=//p' "$MODDIR/build-info.prop" 2>/dev/null | head -n 1)
  status_source_commit=$(sed -n 's/^sourceCommit=//p' "$MODDIR/build-info.prop" 2>/dev/null | head -n 1)

  printf 'RUNNING=%s\n' "$status_running"
  printf 'PID=%s\n' "$status_pid"
  printf 'AUTOSTART=%s\n' "$status_autostart"
  printf 'HOST=%s\n' "$status_host"
  printf 'PORT=%s\n' "$status_port"
  printf 'URL=http://127.0.0.1:%s\n' "$status_port"
  printf 'HTTP_STATUS=%s\n' "$status_http"
  printf 'UPTIME_SECONDS=%s\n' "$status_uptime"
  printf 'START_TIME_EPOCH=%s\n' "${status_start_time:-}"
  printf 'LAST_START_TIME_EPOCH=%s\n' "${status_last_start_time:-}"
  printf 'WATCHDOG_STATUS=%s\n' "$status_watchdog"
  printf 'LAST_RESTART_REASON=%s\n' "${status_last_restart_reason:-none}"
  printf 'LAST_RESTART_TIME_EPOCH=%s\n' "${status_last_restart_time:-}"
  printf 'BINARY_STATUS=%s\n' "$status_binary"
  printf 'PERMISSION_STATUS=%s\n' "$status_permission"
  printf 'CONFIG_STATUS=%s\n' "$status_config"
  printf 'LISTENER_STATUS=%s\n' "$status_listener"
  printf 'WRAPPER_STATUS=%s\n' "$status_wrapper_health"
  printf 'WRAPPERS=%s\n' "$status_wrappers"
  # VERSION is retained for older WebUI clients; new clients use the explicit fields.
  printf 'VERSION=%s\n' "$status_module_version"
  printf 'MODULE_VERSION=%s\n' "$status_module_version"
  printf 'BINARY_VERSION=%s\n' "$status_binary_version"
  printf 'SOURCE_REF=%s\n' "$status_source_ref"
  printf 'SOURCE_COMMIT=%s\n' "$status_source_commit"
  printf 'CONFIG=%s\n' "$PICO_CONFIG"
  printf 'LOG=%s\n' "$PICO_LOG"
}

usage() {
  printf '%s\n' 'Usage: picoclaw-ctl {status|diagnostics|start|stop|restart|toggle|autostart|port|backup|restore|wrappers|logs|url}'
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
  diagnostics)
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
    launcher_toggle
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
      if ! launcher_port_is_safe "$new_port"; then
        module_log "Port harus berupa angka aman antara $PICO_MIN_SAFE_PORT dan $PICO_MAX_SAFE_PORT; port sistem/browser yang diblokir juga ditolak." >&2
        exit 1
      fi
      if ! launcher_lock_acquire port; then
        exit 1
      fi
      old_port=$(launcher_port)
      if ! write_setting_unlocked PORT "$new_port"; then
        launcher_lock_release
        exit 1
      fi
      if launcher_is_running && ! launcher_restart_unlocked 'port changed'; then
        write_setting_unlocked PORT "$old_port" || true
        launcher_start_unlocked >/dev/null 2>&1 || true
        launcher_lock_release
        module_log "Launcher gagal dipindahkan ke port $new_port; port dikembalikan ke $old_port." >&2
        exit 1
      fi
      launcher_lock_release
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
    backup_run "$dest_file"
    ;;
  restore)
    src_file=${2:-}
    restore_run "$src_file"
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
          tail -n "$log_lines" "$PICO_LOG" | redact_log_stream
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
