# Maintainer notes — `device/gpd/xdplus` (TWRP)

Working knowledge for whoever builds and iterates on this tree. `README.md` is the reader-facing document; this file is the stuff that only matters once you are actually rebuilding, re-theming or re-basing it.

## Incremental builds of this tree are not trustworthy — always build cold

Two independent staging failures here produce an image that *looks* built and boots into a broken recovery, while the build reports success in a few seconds:

- **Theme resources.** `gui/libguitwrp_defaults.go` copies `twres/` into `$OUT/recovery/root/` during Soong **analysis**, not from a ninja rule. Delete the staging directory and nothing recreates it — the image packs with no fonts and no images, and TWRP boots to a **black screen** because it has nothing to draw. Upstream ships a workaround for exactly this: `vendor/twrp/Android.mk` toggles `vendor/twrp/dummy/Android.bp` to force Soong to re-run.
- **Native libraries.** A changed `BoardConfig.mk` flag recompiles the object (`events.o`) and relinks the `.so` in `out/soong/.intermediates/`, but the copy already staged under `$OUT/recovery/root/system/lib64/` is **not refreshed**. The image is then packed from the stale library and silently lacks the change. Deleting the staged file does not help: ninja has no rule to restore it and leaves the image untouched.

So the only reliable sequence after touching anything is:

```bash
rm -rf out/target/product/xdplus
touch vendor/twrp/dummy/Android.bp
mka recoveryimage
```

**Verify before flashing, every time** — all three, because each caught a real defect here:

1. staged `recovery/root/system/lib64/libminuitwrp.so` md5 equals the freshly linked `out/soong/.intermediates/.../libminuitwrp.so`;
2. `recovery/root/twres/` is populated;
3. the image size matches the last known-good (a change of a few MB means missing files, and **an image md5 that did not change after a rebuild means nothing was rebuilt**).

## Board flags here are mostly `ifneq (…,)`, so `:= false` turns things ON

`bootable/recovery/Android.mk` tests most TWRP board flags for *non-empty*, not for `true`:

```make
ifneq ($(RECOVERY_SDCARD_ON_DATA),)
	LOCAL_CFLAGS += -DRECOVERY_SDCARD_ON_DATA
endif
```

So `RECOVERY_SDCARD_ON_DATA := false` still defines the macro and still enables the behaviour. A flag meant to be off must be **left undefined**, and the check is a grep on the generated build file rather than a read of `BoardConfig.mk`:

```bash
grep -o DRECOVERY_SDCARD_ON_DATA out/build-twrp_xdplus.ninja   # must print nothing
strings $OUT/recovery/root/system/bin/recovery | grep RECOVERY_SDCARD_ON_DATA
```

A handful of flags nearby do use `ifeq ($(...), true)` — `BOARD_HAS_NO_REAL_SDCARD` is one — so the form is per-flag and worth reading each time.

**Related, and not a board flag at all**: `partitionmanager.cpp` re-enables `datamedia` on its own when no partition is marked settings-storage and a `/data` partition exists. Turning the define off is therefore only half of keeping recovery off `/data`; the other half is `settingsstorage` on `/external_sd` in `twrp.fstab`. ⚠️ That scan requires `Is_Present`, and the microSD is `removable` — **with no card inserted the fallback returns and TWRP writes to `/data` again**.

## The by-name path symlink is load-bearing

`recovery/root/init.recovery.mt8173.rc` contains:

```
on fs
    mkdir /dev/block/platform/mtk-msdc.0
    symlink ../soc/11230000.mmc /dev/block/platform/mtk-msdc.0/11230000.MSDC0
```

The recovery kernel exposes block devices under `/dev/block/platform/soc/11230000.mmc/by-name`, while the running Android system exposes them under `/dev/block/platform/mtk-msdc.0/11230000.MSDC0/by-name`. That symlink is what makes the second form resolve in recovery, and every flashable zip for this device — including the stock ones — writes partitions through it. **Removing it silently breaks partition writes from recovery.**

## Theme placeholders are not substituted on the custom path

`copyCustomTheme()` runs *after* `copyThemeResources()` and overwrites its output, so `{themeversion}`, `{battery_pos}`, `{cpu_pos}`, `{clock_12_pos}`, `{clock_24_pos}` and `{statusicons_align}` must all be resolved by hand in `theme/ui.xml`.

A stale `{themeversion}` makes TWRP silently fall back to the stock theme; unresolved position placeholders evaluate to 0 and stack the status bar items on top of each other.

Gate on `grep -c '{[a-z_0-9]*}' == 0` in the installed `twres/ui.xml`.

## Iterate with Reload Theme, not reboots

Zip the build's staged `twres/` and push it to `/data/media/0/TWRP/theme/ui.zip`, then use Advanced → Reload Theme.

Two packaging rules: entries must not carry a `./` prefix, and **language XMLs must sit at the archive root** — when a theme comes from a package TWRP extracts it to `/twres/customlanguages/` and scans only that directory's top level, so languages nested under `languages/` leave the language list empty. That affects packaged themes only; the built-in path scans `/twres/languages/`.

⚠️ **Delete the test zip afterwards** — it is loaded on every boot and will keep overriding the flashed theme.

## Version policy — track the OS, not TWRP releases

A newer TWRP base is forced by dynamic partitions, A/B, `vendor_boot`, or FBE/metadata encryption. This device has none of them — which is also why TWRP needs no vendor blobs and no keymaster/gatekeeper HAL here — so an Android 11 recovery services this ROM completely, and chasing newer TWRP releases for their own sake buys nothing.

**Add a new `android-*` branch only if the ROM moves to a newer Android.** Two things in this tree are base-specific: the `base.mk` + `core_64_bit.mk` inherit (AOSP 11 removed `embedded.mk`, which every pre-11 TWRP tree names) and the patches under `patches/`. Everything else — board flags, fstab, `init.recovery.*.rc`, rotation, touch transform, theme — carries forward unchanged.

⚠️ On a much newer base, note the one issue that does not apply today: Android 14 userspace on this 3.18 kernel relies on bionic fallbacks for `statx`, `faccessat2` and `clone3` that are probable rather than proven, and any failure surfaces at runtime rather than at build time.
