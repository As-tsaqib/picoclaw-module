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
PICO_TMP_DIR=$PICO_DATA_DIR/tmp
PICO_CORE_BIN=$MODDIR/bin/picoclaw
PICO_LAUNCHER_BIN=$MODDIR/bin/picoclaw-launcher

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
      printf 'PORT=18800\n'
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
  selected_port=$(read_setting PORT 18800)
  case "$selected_port" in
    ''|*[!0-9]*) selected_port=18800 ;;
    *)
      if [ "$selected_port" -lt 1 ] || [ "$selected_port" -gt 65535 ]; then
        selected_port=18800
      fi
      ;;
  esac
  printf '%s\n' "$selected_port"
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

launcher_is_running() {
  running_pid=$(launcher_pid 2>/dev/null) || return 1
  [ -d "/proc/$running_pid" ] || return 1
  kill -0 "$running_pid" 2>/dev/null || return 1
  tr '\000' ' ' < "/proc/$running_pid/cmdline" 2>/dev/null | grep -Fq "$PICO_LAUNCHER_BIN"
}

launcher_start() {
  ensure_data_dirs
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

launcher_stop() {
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
  rm -f "$PICO_PID_FILE"
  module_log "Launcher dihentikan."
}

launcher_restart() {
  launcher_stop
  launcher_start
}
