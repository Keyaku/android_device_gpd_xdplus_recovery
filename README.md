# TWRP device tree — GPD XD+ (`xdplus`)

Recovery device tree for the GPD XD+ / XD Plus, a MediaTek MT8176 (MT8173 platform, PowerVR GX6250) handheld.

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

### ⚠️ Incremental builds of this tree are not trustworthy — always build cold

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

### The kernel is not built here

`TARGET_PREBUILT_KERNEL` points at `prebuilt/Image.gz-dtb`, which is gitignored. Copy in the `Image.gz-dtb` produced by the device's LineageOS 18.1 tree (kernel `3.18.79`) before building. Building the kernel from source inside the recovery tree is possible but pulls a second copy of the kernel and its toolchain into this checkout for no benefit — the ROM tree already builds it.

## ⚠️ The by-name path symlink is load-bearing

`recovery/root/init.recovery.mt8173.rc` contains:

```
on fs
    mkdir /dev/block/platform/mtk-msdc.0
    symlink ../soc/11230000.mmc /dev/block/platform/mtk-msdc.0/11230000.MSDC0
```

The recovery kernel exposes block devices under `/dev/block/platform/soc/11230000.mmc/by-name`, while the running Android system exposes them under `/dev/block/platform/mtk-msdc.0/11230000.MSDC0/by-name`. That symlink is what makes the second form resolve in recovery, and every flashable zip for this device — including the stock ones — writes partitions through it. **Removing it silently breaks partition writes from recovery.**

## ⚠️ Flashing this is the riskiest operation on this device

The bootloader is locked, so there is no `fastboot flash`, and recovery is the only way back from a bad boot or system image.

- Back up the current recovery partition first and keep it.
- **Never flash a new recovery in the same session as a new boot or system image.** Flash recovery alone, confirm the device still boots and still has root, and only then reboot into the new recovery to test it.
- A bad recovery on its own is survivable — write the backup back to the recovery partition from a booted, rooted system. A bad recovery *plus* a bad boot means SP Flash Tool.

## Status

**Builds.** `mka recoveryimage` produces **TWRP 3.7.0_11-0**, 22,466,560 bytes, whose boot header matches the shipped 3.4.0-0 image exactly (kernel `0x40080000`, ramdisk `0x49000000`, page 2048, header v0). The ramdisk carries this tree's fstab, both `init.recovery.*.rc` and `ueventd.mt8173.rc`.

**Not yet flashed or booted.** Everything above is a build-time result; nothing here has run on the device. See the flashing warning above before changing that.

Requires `patches/0001` against `bootable/recovery` — see `patches/README.md`.

## Credits

- Goayandi — the original `gpd_en` minimal TWRP tree the board flags come from.
- BlackSeraph — the 3.4.0-0 build this tree reconstructs.
- TeamWin — TWRP.
