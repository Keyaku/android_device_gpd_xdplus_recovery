# Maintainer notes — `device/gpd/xdplus` (TWRP)

Working knowledge for whoever builds and iterates on this tree. `README.md` is the reader-facing document; this file is the stuff that only matters once you are actually rebuilding, re-theming or re-basing it.

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
