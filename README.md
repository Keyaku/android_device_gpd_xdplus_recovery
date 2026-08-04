# TWRP device tree — GPD XD+ (`xdplus`)

Recovery device tree for the GPD XD+ / XD Plus, a MediaTek MT8176 (MT8173 platform, PowerVR GX6250) handheld.

It belongs to the [`Keyaku/gpd-xdplus-customrom`](https://github.com/Keyaku/gpd-xdplus-customrom) project — the LineageOS 18.1 port for this device. That repository is where installation, flashing and the rest of the ROM are documented; this one is only the recovery.

## Why this tree exists

The recovery running on these devices is **TWRP 3.4.0-0**, built on 2020-08-25 against an Android 8.1 omni tree with a `3.18.79+ #36` recovery kernel. **Its source was never published** — the only public trees for this hardware are the 2018 `gpd_en` minimal tree (twrp-7.1, with a 2018 `3.18.35` prebuilt kernel that does not match what is flashed) and an Android 8.1-era ROM device tree under the older `xds` codename. So the recovery could not be rebuilt, patched or updated by anyone.

This tree reconstructs it on a current base. Everything under `recovery/root/` was recovered verbatim from the ramdisk of the shipped image; the board flags were carried over from the `gpd_en` tree and then verified against that image's boot header rather than trusted.

Codename is **`xdplus`**, which is what the shipped recovery itself reports (`ro.product.device`, `ro.omni.device`) — not the OEM's `xds`, and not `gpd_en`.

## Building

Base is the TWRP minimal AOSP manifest, Android 11 branch:

```bash
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-11
repo sync
```

Place this tree at `device/gpd/xdplus`, apply the patches in `patches/` (see `patches/README.md`), then:

```bash
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch twrp_xdplus-eng
mka recoveryimage
```

⚠️ This tree must be a **real directory** at `device/gpd/xdplus`, not a symlink to one elsewhere — the build locates products with `find`, which does not follow symlinks, and the product simply will not be found.

Build cold — `rm -rf out/target/product/xdplus` before every rebuild. Incremental builds of this tree are not trustworthy; `CLAUDE.md` has the reason and the full sequence.

### The kernel is not built here

`TARGET_PREBUILT_KERNEL` points at `prebuilt/Image.gz-dtb`, which is gitignored. Copy in the `Image.gz-dtb` produced by the device's LineageOS 18.1 tree (kernel `3.18.79`) before building. Building the kernel from source inside the recovery tree is possible but pulls a second copy of the kernel and its toolchain into this checkout for no benefit — the ROM tree already builds it.

## Flashing

The bootloader is locked, so images are written with `dd` from a rooted system or from TWRP rather than with `fastboot flash`. That is a difference in method, not a risk: this SoC's boot ROM download mode is fully open on this device, so the preloader channel can read and write every partition regardless of the lock state, and no partition write is one-way.

Practical habits, not warnings:

- Keep a copy of the current recovery partition — it is the fastest way back, and much quicker than going through the preloader.
- Flash recovery on its own, confirm the device still boots, then reboot into the new recovery to test it.

The full flashing procedure for this device — including recovery — is documented in the umbrella ROM repository, [`Keyaku/gpd-xdplus-customrom`](https://github.com/Keyaku/gpd-xdplus-customrom), which is the right place to follow along from.

## Status

**Working on hardware.** `mka recoveryimage` produces **TWRP 3.7.0_11-0**, 22,464,512 bytes, whose boot header matches the shipped 3.4.0-0 image exactly (kernel `0x40080000`, ramdisk `0x49000000`, page 2048, header v0).

Flashed and verified on the device:

- boots, displays landscape, and touch tracks correctly;
- `adb` works in recovery;
- `/data`, `/system_root` and `/vendor` all mount from the real partitions;
- writes a partition **by name**, through both the `soc/11230000.mmc` and `mtk-msdc.0` forms.

### Interface

The stock landscape theme is designed for a 1920×1200 coordinate space, which scales badly onto this panel. `TW_CUSTOM_THEME` points at `theme/ui.xml`, derived from `landscape_hdpi` with:

- the on-screen navigation bar removed (this device has physical buttons) and the coordinate space reduced 1200 → 1104 to reclaim it, which also scales the whole UI up ~9% and brings the vertical scale (0.652) closer to the horizontal (0.667);
- larger text where it was hardest to read — `font_m` 32 → 46 (checkboxes, lists, list items), `font_s` 28 → 36 (tabs) — while `font_l` (main buttons) stays at 50;
- a dedicated `font_status` for the status bar, so tuning list text no longer pushes the clock, CPU and battery readouts into each other.

`patches/0002` drops the now-meaningless navbar settings and the "Install TWRP App" entry from the shared `landscape.xml` pages.

Requires `patches/0001` against `bootable/recovery` — see `patches/README.md`.

This tree targets the **`twrp-11` base (Android 11)**, matching the ROM it services; the branch is named `android-11` after that base.

## Credits

- Goayandi — the original `gpd_en` minimal TWRP tree the board flags come from.
- BlackSeraph — the 3.4.0-0 build this tree reconstructs.
- TeamWin — TWRP.
