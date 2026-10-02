#!/system/bin/sh
# late_start service: never block boot; wait for boot_completed, then start the daemon.
MODDIR="${0%/*}"
(
    n=0
    until [ "$(getprop sys.boot_completed)" = "1" ] || [ "$n" -ge 120 ]; do
        sleep 2
        n=$((n + 1))
    done
    sleep 5
    rm -rf /data/adb/wwan-wg/run        # stale pid / lock / cache from the previous boot
    /system/bin/sh "$MODDIR/bin/controller" start
) >/dev/null 2>&1 &
exit 0
