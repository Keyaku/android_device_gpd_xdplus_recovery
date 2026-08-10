# BoardConfig for the GPD XD+ (xdplus) TWRP recovery.
#
# Values marked "verified" were read out of the recovery image that ships on the
# device (TWRP 3.4.0-0, md5 7d116c05b17714fefbcb746eab525dbe), not copied from
# an older tree on faith.

DEVICE_PATH := device/gpd/xdplus

# Bootloader — not built or flashed from this tree; images are written with dd.
TARGET_NO_BOOTLOADER := true
TARGET_BOOTLOADER_BOARD_NAME :=

# Platform
TARGET_BOARD_PLATFORM := mt8173

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a15

TARGET_USES_64_BIT_BINDER := true

# Kernel
# Built out of the LineageOS tree (kernel/gpd/mt8176, 3.18.79) and copied in;
# this tree does not build the kernel itself. See README.md.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb

# verified: matches the shipped recovery's boot header byte for byte
# (kernel_addr 0x40080000, ramdisk_addr 0x49000000, page 2048, header v0).
# The build appends buildvariant= itself; do not repeat it here. Keep this
# short — the bootloader truncates the command line it passes on.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 --ramdisk_offset 0x08f88000 \
    --second_offset 0x00e88000 --tags_offset 0x0df88000 --header_version 0

# Partitions
# The stock scatter declares boot and recovery as 0x4000000 each, but the live
# mmcblk0p8 measures 96 MB; the shipped 16 MB recovery.img is simply padded with
# zeroes out to the partition size. 0x6000000 is the observed truth.
BOARD_BOOTIMAGE_PARTITION_SIZE := 0x4000000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x6000000
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USES_MKE2FS := true

# No A/B, no dynamic partitions, no recovery-as-boot.
AB_OTA_UPDATER := false
BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := ABGR_8888
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/fstab.mt8173
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_INCREASES_COLDBOOT_TIMEOUT := true

# Display — 720x1280 portrait-native panel on a device held in landscape.
# The panel scans portrait and is mounted upside-down (the ROM compensates with
# ro.sf.hwrotation=180). 180 of rotation undoes the mount, plus 90 to reach the
# landscape orientation the device is actually held in.
TW_THEME := landscape_hdpi
TW_ROTATION := 270

# Custom ui.xml derived from landscape_hdpi: the on-screen navigation bar is
# redundant on a device with physical buttons, so it is removed and the theme's
# coordinate space shrinks from 1200 to 1104 (where the navbar began). That also
# scales the UI up — 720/1104 = 0.652 against the old 720/1200 = 0.600 — and
# brings the vertical scale closer to the horizontal 1280/1920 = 0.667, so the
# layout is less distorted than before. Lowest row the theme actually uses is
# row18_y = 1008, so nothing is clipped.
#
# ⚠️ Only ui.xml is replaced; images, fonts, languages and common/landscape.xml
# still come from TW_THEME above, so both must stay set.
# ⚠️ The custom-theme path is a plain file copy with no {themeversion}
# substitution, so the literal version is baked into the file. If it ever
# mismatches variables.h's TW_THEME_VERSION, TWRP silently falls back to the
# stock theme with "theme version from xml: 0, expected N" in the log.
TW_CUSTOM_THEME := device/gpd/xdplus/theme/ui.xml
DEVICE_RESOLUTION := 720x1280
DEVICE_SCREEN_WIDTH := 720
DEVICE_SCREEN_HEIGHT := 1280
BOARD_USE_FRAMEBUFFER_ALPHA_CHANNEL := true
TARGET_DISABLE_TRIPLE_BUFFERING := false

# ⚠️ TW_ROTATION rotates GRAPHICS ONLY — minuitwrp's touch path (events.cpp)
# knows nothing about it and supports just SWAP_XY / FLIP_X / FLIP_Y. The input
# transform therefore has to reproduce the rotation by hand.
#
# Derivation, so this is checkable rather than folklore. At TW_ROTATION 270,
# gr_clip maps a screen point (sx,sy) onto panel pixel (sy, 1280-sx). The panel
# is mounted 180 off, which at rotation 0 needed FLIP_X+FLIP_Y, i.e. panel_x =
# 720-px and panel_y = 1280-py. Combining the two gives sx = py and
# sy = 720-px — that is SWAP_XY followed by FLIP_Y, and no FLIP_X.
RECOVERY_TOUCHSCREEN_SWAP_XY := true
RECOVERY_TOUCHSCREEN_FLIP_Y := true
# RECOVERY_TOUCHSCREEN_FLIP_X := true

# Storage
TW_INTERNAL_STORAGE_PATH := "/data/media"
TW_INTERNAL_STORAGE_MOUNT_POINT := "data"
TW_EXTERNAL_STORAGE_PATH := "/external_sd"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "external_sd"
# Storage must NOT live on /data. This recovery cannot decrypt, so with
# RECOVERY_SDCARD_ON_DATA defined it stored its settings and logs in
# /data/media/0/TWRP -- writing PLAINTEXT names into an ext4 directory that
# carries an fscrypt policy. That produces malformed encrypted dirents, proved
# on hardware by e2fsck: "Encrypted entry 'TWRP' in /media/0 is too short",
# leaving the filesystem with errors. The same corruption shape is what makes
# /data/misc/vold a dirent whose stat() fails, which kills vold's
# fscrypt_init_user0 and reboots the device into recovery on boot.
# The microSD is the storage instead; zips go to /external_sd or /tmp, which is
# what the flashing workflow already does.
#
# RECOVERY_SDCARD_ON_DATA is deliberately LEFT UNSET, never set to false:
# bootable/recovery/Android.mk gates it with ifneq ($(...),), so ANY non-empty
# value -- including "false" -- adds -DRECOVERY_SDCARD_ON_DATA and turns the
# behaviour back on. Verify with:
#   grep -o DRECOVERY_SDCARD_ON_DATA out/build-twrp_xdplus.ninja
# which must print nothing.
#
# Unsetting it is necessary but NOT sufficient: partitionmanager.cpp turns
# datamedia back on by itself when no settings storage is present and there is
# a /data partition. The microSD carries the "settingsstorage" flag in
# twrp.fstab to claim that role before that fallback runs.
# RECOVERY_SDCARD_ON_DATA is intentionally not defined here.
TW_DEFAULT_EXTERNAL_STORAGE := true
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/class/android_usb/android0/f_mass_storage/lun/file

# Crypto. ⚠️ The old comment here claimed this device uses neither FDE nor FBE.
# That was true of the shipped ROM and is no longer a safe assumption: FBE v1
# has been run on this device, and a recovery that cannot decrypt must at least
# not WRITE to /data (see RECOVERY_SDCARD_ON_DATA above). Adding real decrypt
# support means dragging keymaster/gatekeeper and the TEE blobs into the
# recovery ramdisk; that stays a separate, deliberate piece of work.
# TW_INCLUDE_CRYPTO is intentionally not defined here -- see CLAUDE.md.
# TW_EXCLUDE_ENCRYPTED_BACKUPS is gated the other way round; keep it set.
TW_EXCLUDE_ENCRYPTED_BACKUPS := false

# Filesystems: the kernel has CONFIG_EXFAT_FS=y, but keep the userspace tools so
# a card formatted by anything else still mounts.
TW_NO_EXFAT := false
TW_NO_EXFAT_FUSE := false

# Misc
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_DEFAULT_BRIGHTNESS := 128
TW_CUSTOM_CPU_TEMP_PATH := /sys/devices/virtual/thermal/thermal_zone1/temp
TW_IGNORE_MISC_WIPE_DATA := true
TW_EXCLUDE_SUPERSU := true
TW_INCLUDE_FB2PNG := true
TW_EXTRA_LANGUAGES := true
TW_USE_TOOLBOX := true

# TODO: this device has an analog stick and gamepad buttons on its own input
# devices; if TWRP misreads them as touch, blacklist them here by input device
# name (see /proc/bus/input/devices on the running system).
# TW_INPUT_BLACKLIST := "adc_js"
