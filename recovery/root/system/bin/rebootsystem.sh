#!/sbin/sh
#
# Run by TWRP (TWFunc::tw_reboot -> check_and_run_script) immediately before it
# reboots to the system. TWRP itself never touches the BCB, so a device that
# entered recovery via `adb reboot recovery`, an OTA, or init's
# init_user0_failed path would find the same command still in `para` on the next
# boot and LK would loop straight back into recovery.
#
# Clear only the first 2048 bytes: `para` also holds LK's ENV_v1, and zeroing
# the partition wholesale destroys it.
#
# Both by-name forms are tried. Recovery exposes the `soc/11230000.mmc` path;
# the `mtk-msdc.0` form exists here only because init.recovery.mt8173.rc
# symlinks it, so it may not be present depending on when this runs.
for BYNAME in /dev/block/platform/soc/11230000.mmc/by-name \
              /dev/block/platform/mtk-msdc.0/11230000.MSDC0/by-name; do
	[ -e "$BYNAME/para" ] || continue
	dd if=/dev/zero of="$BYNAME/para" bs=2048 count=1 conv=notrunc 2>/dev/null && break
done
sync
