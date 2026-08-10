#!/system/bin/sh

ui_print '***************************************'
ui_print '             PicoClaw Module           '
ui_print '***************************************'

case "$ARCH" in
  arm64)
    ui_print '- ABI: arm64 (didukung)'
    ;;
  *)
    abort "! ABI $ARCH tidak didukung; upstream hanya menyediakan target Android ARM64."
    ;;
esac

if [ ! -f "$MODPATH/bin/picoclaw" ] || [ ! -f "$MODPATH/bin/picoclaw-launcher" ]; then
  abort '! ZIP tidak lengkap: binary PicoClaw hilang.'
fi

set_perm "$MODPATH/bin/picoclaw" 0 0 0755
set_perm "$MODPATH/bin/picoclaw-launcher" 0 0 0755
for module_script in \
  "$MODPATH/common.sh" \
  "$MODPATH/control.sh" \
  "$MODPATH/termux.sh" \
  "$MODPATH/post-fs-data.sh" \
  "$MODPATH/service.sh" \
  "$MODPATH/action.sh" \
  "$MODPATH/uninstall.sh" \
  "$MODPATH/termux/picoclaw-wrapper"; do
  set_perm "$module_script" 0 0 0755
done

MODDIR=$MODPATH
# shellcheck source=module/common.sh
. "$MODPATH/common.sh"
# shellcheck source=module/termux.sh
. "$MODPATH/termux.sh"
ensure_data_dirs

ui_print '- Memasang wrapper CLI ke Termux...'
if ! install_termux_wrappers; then
  ui_print '! Termux belum ditemukan; pasang wrapper nanti dari Action/WebUI.'
fi

ui_print '- Dashboard akan tersedia di http://127.0.0.1:18800'
ui_print '- Reboot perangkat setelah instalasi.'
ui_print '- Config/data dipertahankan di /data/adb/picoclaw.'
