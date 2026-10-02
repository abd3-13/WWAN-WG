#!/system/bin/sh
# Sourced by the KernelSU installer after files are extracted.
DATA=/data/adb/wwan-wg
OLD_CONF=/data/adb/modules/wwan-wg/config/config.conf   # v0.2.x location

ui_print "- WWAN-WG 0.3.2"
[ "$ARCH" = "arm64" ] || ui_print "! ARCH=$ARCH: only arm64 binaries are expected in bin/"

mkdir -p "$DATA/log" "$DATA/run"
if [ -f "$DATA/config.conf" ]; then
    ui_print "- Keeping existing $DATA/config.conf"
elif [ -f "$OLD_CONF" ]; then
    cp "$OLD_CONF" "$DATA/config.conf"
    ui_print "- Migrated config from v0.2.x"
else
    cp "$MODPATH/config/config.default" "$DATA/config.conf"
    ui_print "- Wrote default config: $DATA/config.conf"
fi
chmod 600 "$DATA/config.conf"

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

[ -f "$MODPATH/bin/wg" ] || ui_print "! No bin/wg bundled: 'wg' must be in PATH or copied to $MODPATH/bin"
