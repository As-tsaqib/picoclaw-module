#!/system/bin/sh

TERMUX_PREFIX=/data/data/com.termux/files/usr
TERMUX_BIN=$TERMUX_PREFIX/bin
TERMUX_WRAPPER_NAMES='picoclaw picoclaw-config picoclaw-onboard picoclaw-agent picoclaw-auth picoclaw-gateway picoclaw-status picoclaw-cron picoclaw-mcp picoclaw-migrate picoclaw-skills picoclaw-model picoclaw-update picoclaw-version picoclaw-launcher picoclaw-web picoclaw-ctl'

is_picoclaw_wrapper() {
  wrapper_path=$1
  [ -f "$wrapper_path" ] && grep -q '^# PICOCLAW_MODULE_WRAPPER=1$' "$wrapper_path" 2>/dev/null
}

fix_termux_file_metadata() {
  metadata_target=$1
  reference_file=$TERMUX_BIN/sh
  termux_owner=$(stat -c '%u:%g' "$TERMUX_BIN" 2>/dev/null || true)

  if [ -n "$termux_owner" ]; then
    chown "$termux_owner" "$metadata_target" 2>/dev/null || true
  fi
  chmod 0700 "$metadata_target" 2>/dev/null || true
  if [ -e "$reference_file" ]; then
    chcon --reference="$reference_file" "$metadata_target" 2>/dev/null || true
  fi
  restorecon "$metadata_target" 2>/dev/null || true
}

install_termux_wrappers() {
  termux_template=$MODDIR/termux/picoclaw-wrapper
  installed_count=0
  skipped_count=0

  if [ ! -d "$TERMUX_BIN" ]; then
    printf '[PicoClaw] Termux belum ditemukan di %s.\n' "$TERMUX_PREFIX"
    return 1
  fi
  if [ ! -f "$termux_template" ]; then
    printf '[PicoClaw] Template wrapper tidak ditemukan.\n'
    return 1
  fi

  for wrapper_name in $TERMUX_WRAPPER_NAMES; do
    wrapper_target=$TERMUX_BIN/$wrapper_name
    wrapper_backup=$TERMUX_BIN/.${wrapper_name}.picoclaw-module.bak
    wrapper_temp=$TERMUX_BIN/.${wrapper_name}.picoclaw-module.tmp.$$

    if [ -e "$wrapper_target" ] || [ -L "$wrapper_target" ]; then
      if is_picoclaw_wrapper "$wrapper_target"; then
        rm -f "$wrapper_target"
      elif [ ! -e "$wrapper_backup" ] && [ ! -L "$wrapper_backup" ]; then
        mv "$wrapper_target" "$wrapper_backup"
      else
        printf '[PicoClaw] Lewati %s: command lama dan backup sama-sama ada.\n' "$wrapper_name"
        skipped_count=$((skipped_count + 1))
        continue
      fi
    fi

    cp "$termux_template" "$wrapper_temp"
    fix_termux_file_metadata "$wrapper_temp"
    mv "$wrapper_temp" "$wrapper_target"
    installed_count=$((installed_count + 1))
  done

  printf '[PicoClaw] %s wrapper Termux dipasang, %s dilewati.\n' "$installed_count" "$skipped_count"
  [ "$installed_count" -gt 0 ] || [ "$skipped_count" -eq 0 ]
}

remove_termux_wrappers() {
  removed_count=0

  [ -d "$TERMUX_BIN" ] || return 0
  for wrapper_name in $TERMUX_WRAPPER_NAMES; do
    wrapper_target=$TERMUX_BIN/$wrapper_name
    wrapper_backup=$TERMUX_BIN/.${wrapper_name}.picoclaw-module.bak

    if is_picoclaw_wrapper "$wrapper_target"; then
      rm -f "$wrapper_target"
      removed_count=$((removed_count + 1))
      if [ -e "$wrapper_backup" ] || [ -L "$wrapper_backup" ]; then
        mv "$wrapper_backup" "$wrapper_target"
      fi
    fi
  done
  printf '[PicoClaw] %s wrapper Termux dilepas.\n' "$removed_count"
}

termux_wrappers_status() {
  wrapper_total=0
  wrapper_ready=0

  if [ ! -d "$TERMUX_BIN" ]; then
    printf 'termux-not-found\n'
    return 0
  fi
  for wrapper_name in $TERMUX_WRAPPER_NAMES; do
    wrapper_total=$((wrapper_total + 1))
    if is_picoclaw_wrapper "$TERMUX_BIN/$wrapper_name"; then
      wrapper_ready=$((wrapper_ready + 1))
    fi
  done
  if [ "$wrapper_ready" -eq "$wrapper_total" ]; then
    printf 'ready\n'
  elif [ "$wrapper_ready" -eq 0 ]; then
    printf 'missing\n'
  else
    printf 'partial-%s-of-%s\n' "$wrapper_ready" "$wrapper_total"
  fi
}
