#!/system/bin/sh

if [ -z "${MODDIR:-}" ]; then
  MODDIR=${0%/*}
fi

PICO_DATA_DIR=/data/adb/picoclaw
PICO_HOME=$PICO_DATA_DIR
PICO_CONFIG=$PICO_DATA_DIR/config.json
PICO_SETTINGS=$PICO_DATA_DIR/settings.conf
PICO_RUN_DIR=$PICO_DATA_DIR/run
PICO_LOG_DIR=$PICO_DATA_DIR/logs
PICO_LOG=$PICO_LOG_DIR/launcher-module.log
PICO_PID_FILE=$PICO_RUN_DIR/launcher.pid
PICO_MANUAL_STOP=$PICO_RUN_DIR/manual_stop
PICO_LOCK_DIR=$PICO_RUN_DIR/launcher.lock
PICO_LOCK_PID_FILE=$PICO_LOCK_DIR/pid
PICO_LOCK_OPERATION_FILE=$PICO_LOCK_DIR/operation
PICO_TMP_DIR=$PICO_DATA_DIR/tmp
PICO_CORE_BIN=$MODDIR/bin/picoclaw
PICO_LAUNCHER_BIN=$MODDIR/bin/picoclaw-launcher
PICO_DEFAULT_PORT=18800
PICO_MIN_SAFE_PORT=1024
PICO_MAX_SAFE_PORT=65535

module_log() {
  printf '[PicoClaw] %s\n' "$*"
}

ensure_data_dirs() {
  umask 077
  mkdir -p "$PICO_DATA_DIR" "$PICO_RUN_DIR" "$PICO_LOG_DIR" "$PICO_TMP_DIR"
  if [ ! -f "$PICO_SETTINGS" ]; then
    {
      printf 'AUTOSTART=1\n'
      printf 'HOST=127.0.0.1\n'
      printf 'PORT=%s\n' "$PICO_DEFAULT_PORT"
    } > "$PICO_SETTINGS"
  fi
  chmod 0700 "$PICO_DATA_DIR" "$PICO_RUN_DIR" "$PICO_LOG_DIR" "$PICO_TMP_DIR" 2>/dev/null || true
  chmod 0600 "$PICO_SETTINGS" 2>/dev/null || true
}

read_setting() {
  setting_key=$1
  setting_default=$2
  setting_value=

  if [ -f "$PICO_SETTINGS" ]; then
    setting_value=$(sed -n "s/^${setting_key}=//p" "$PICO_SETTINGS" | tail -n 1)
  fi
  if [ -z "$setting_value" ]; then
    setting_value=$setting_default
  fi
  printf '%s\n' "$setting_value"
}

launcher_port() {
  selected_port=$(read_setting PORT "$PICO_DEFAULT_PORT")
  if ! launcher_port_is_safe "$selected_port"; then
    selected_port=$PICO_DEFAULT_PORT
  fi
  printf '%s\n' "$selected_port"
}

# Keep the launcher on a non-privileged port that browsers can access. Chrome
# and Chromium reject a small set of otherwise valid ports for security; keep
# those out of the UI and the root control path as well.
launcher_port_is_safe() {
  safe_port=$1
  case "$safe_port" in
    ''|*[!0-9]*) return 1 ;;
  esac
  if [ "$safe_port" -lt "$PICO_MIN_SAFE_PORT" ] ||
    [ "$safe_port" -gt "$PICO_MAX_SAFE_PORT" ]; then
    return 1
  fi
  case "$safe_port" in
    2049|3659|4045|5060|6000|6566|6665|6666|6667|6668|6669|6697|10080)
      return 1
      ;;
  esac
  return 0
}

launcher_host() {
  selected_host=$(read_setting HOST 127.0.0.1)
  case "$selected_host" in
    127.0.0.1|localhost) printf '127.0.0.1\n' ;;
    *) printf '127.0.0.1\n' ;;
  esac
}

launcher_pid() {
  [ -f "$PICO_PID_FILE" ] || return 1
  pid_value=$(sed -n '1p' "$PICO_PID_FILE")
  case "$pid_value" in
    ''|*[!0-9]*) return 1 ;;
  esac
  printf '%s\n' "$pid_value"
}

path_exists_or_link() {
  [ -e "$1" ] || [ -L "$1" ]
}

launcher_lock_acquire() {
  ensure_data_dirs
  lock_operation=${1:-lifecycle}
  lock_wait=0

  while ! mkdir "$PICO_LOCK_DIR" 2>/dev/null; do
    lock_pid=
    if [ -f "$PICO_LOCK_PID_FILE" ]; then
      lock_pid=$(sed -n '1p' "$PICO_LOCK_PID_FILE" 2>/dev/null)
    fi

    # A writer may have created the directory just before writing its PID.
    if [ -z "$lock_pid" ]; then
      # Do not reclaim an incompletely initialized lock immediately: the
      # owner can have created the directory and still be writing its PID.
      if [ "$lock_wait" -lt 30 ]; then
        sleep 1
        lock_wait=$((lock_wait + 1))
        continue
      fi
    fi

    lock_pid_alive=0
    case "$lock_pid" in
      ''|*[!0-9]*) ;;
      *)
        if kill -0 "$lock_pid" 2>/dev/null; then
          lock_pid_alive=1
        fi
        ;;
    esac

    if [ "$lock_pid_alive" -eq 0 ]; then
      stale_lock_dir="$PICO_LOCK_DIR.stale.$$.$lock_wait"
      if mv "$PICO_LOCK_DIR" "$stale_lock_dir" 2>/dev/null; then
        rm -rf "$stale_lock_dir" 2>/dev/null || true
        continue
      fi
    fi

    if [ "$lock_wait" -ge 30 ]; then
      module_log "Operasi $lock_operation menunggu lock launcher terlalu lama." >&2
      return 1
    fi
    sleep 1
    lock_wait=$((lock_wait + 1))
  done

  printf '%s\n' "$$" > "$PICO_LOCK_PID_FILE" || {
    rmdir "$PICO_LOCK_DIR" 2>/dev/null || true
    module_log 'Tidak dapat menulis owner lock launcher.' >&2
    return 1
  }
  printf '%s\n' "$lock_operation" > "$PICO_LOCK_OPERATION_FILE" 2>/dev/null || true
  chmod 0600 "$PICO_LOCK_PID_FILE" "$PICO_LOCK_OPERATION_FILE" 2>/dev/null || true
  return 0
}

launcher_lock_release() {
  [ -d "$PICO_LOCK_DIR" ] || return 0
  lock_owner=
  if [ -f "$PICO_LOCK_PID_FILE" ]; then
    lock_owner=$(sed -n '1p' "$PICO_LOCK_PID_FILE" 2>/dev/null)
  fi
  [ "$lock_owner" = "$$" ] || return 0
  rm -f "$PICO_LOCK_PID_FILE" "$PICO_LOCK_OPERATION_FILE" 2>/dev/null || true
  rmdir "$PICO_LOCK_DIR" 2>/dev/null || true
}

launcher_is_running() {
  running_pid=$(launcher_pid 2>/dev/null) || return 1
  [ -d "/proc/$running_pid" ] || return 1
  kill -0 "$running_pid" 2>/dev/null || return 1
  tr '\000' ' ' < "/proc/$running_pid/cmdline" 2>/dev/null | grep -Fq "$PICO_LAUNCHER_BIN"
}

launcher_start_unlocked() {
  rm -f "$PICO_MANUAL_STOP" 2>/dev/null || true

  if launcher_is_running; then
    module_log "Launcher sudah berjalan (PID $(launcher_pid))."
    return 0
  fi

  rm -f "$PICO_PID_FILE"
  if [ ! -x "$PICO_CORE_BIN" ] || [ ! -x "$PICO_LAUNCHER_BIN" ]; then
    module_log "Binary PicoClaw tidak ditemukan atau tidak executable."
    return 1
  fi

  launch_port=$(launcher_port)
  launch_host=$(launcher_host)
  android_tz=$(getprop persist.sys.timezone 2>/dev/null || true)

  export HOME="$PICO_HOME"
  export PICOCLAW_HOME="$PICO_HOME"
  export PICOCLAW_CONFIG="$PICO_CONFIG"
  export PICOCLAW_BINARY="$PICO_CORE_BIN"
  export TMPDIR="$PICO_TMP_DIR"
  export NO_COLOR=1
  export TERM=dumb
  if [ -n "$android_tz" ]; then
    export TZ="$android_tz"
  fi

  nohup "$PICO_LAUNCHER_BIN" \
    -host "$launch_host" \
    -port "$launch_port" \
    -no-browser \
    -console \
    "$PICO_CONFIG" \
    >> "$PICO_LOG" 2>&1 </dev/null &
  launch_pid=$!
  printf '%s\n' "$launch_pid" > "$PICO_PID_FILE"
  chmod 0600 "$PICO_PID_FILE" 2>/dev/null || true

  sleep 1
  if launcher_is_running; then
    module_log "Launcher aktif di http://127.0.0.1:$launch_port (PID $launch_pid)."
    return 0
  fi

  rm -f "$PICO_PID_FILE"
  module_log "Launcher gagal dimulai. Periksa $PICO_LOG."
  return 1
}

launcher_start() {
  if ! launcher_lock_acquire start; then
    return 1
  fi
  launcher_start_unlocked
  launcher_result=$?
  launcher_lock_release
  return "$launcher_result"
}

launcher_stop_unlocked() {
  touch "$PICO_MANUAL_STOP" 2>/dev/null || true

  if ! launcher_is_running; then
    rm -f "$PICO_PID_FILE"
    module_log "Launcher tidak sedang berjalan."
    return 0
  fi

  stop_pid=$(launcher_pid)
  kill "$stop_pid" 2>/dev/null || true
  stop_wait=0
  while kill -0 "$stop_pid" 2>/dev/null && [ "$stop_wait" -lt 15 ]; do
    sleep 1
    stop_wait=$((stop_wait + 1))
  done
  if kill -0 "$stop_pid" 2>/dev/null; then
    kill -9 "$stop_pid" 2>/dev/null || true
  fi
  if kill -0 "$stop_pid" 2>/dev/null; then
    module_log "Launcher PID $stop_pid tidak dapat dihentikan." >&2
    return 1
  fi
  rm -f "$PICO_PID_FILE"
  module_log "Launcher dihentikan."
}

launcher_stop() {
  if ! launcher_lock_acquire stop; then
    return 1
  fi
  launcher_stop_unlocked
  launcher_result=$?
  launcher_lock_release
  return "$launcher_result"
}

launcher_restart_unlocked() {
  launcher_stop_unlocked || return 1
  launcher_start_unlocked
}

launcher_restart() {
  if ! launcher_lock_acquire restart; then
    return 1
  fi
  launcher_restart_unlocked
  launcher_result=$?
  launcher_lock_release
  return "$launcher_result"
}

launcher_toggle() {
  if ! launcher_lock_acquire toggle; then
    return 1
  fi
  if launcher_is_running; then
    launcher_stop_unlocked
  else
    launcher_start_unlocked
  fi
  launcher_result=$?
  launcher_lock_release
  return "$launcher_result"
}

launcher_watchdog_start() {
  if ! launcher_lock_acquire watchdog; then
    return 1
  fi

  if [ "$(read_setting AUTOSTART 1)" = 1 ] &&
    [ ! -f "$PICO_MANUAL_STOP" ] && ! launcher_is_running; then
    module_log 'Watchdog: Launcher terhenti. Memulai ulang service...'
    launcher_start_unlocked
    launcher_result=$?
  else
    launcher_result=0
  fi

  launcher_lock_release
  return "$launcher_result"
}
