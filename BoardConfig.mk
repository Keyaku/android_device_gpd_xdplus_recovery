# BoardConfig for the GPD XD+ (xdplus) TWRP recovery.
#
# Values marked "verified" were read out of the recovery image that ships on the
# device (TWRP 3.4.0-0, md5 7d116c05b17714fefbcb746eab525dbe), not copied from
# an older tree on faith.

DEVICE_PATH := device/gpd/xdplus

# Bootloader — locked, and there is no fastboot flash on this device.
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
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/twrp.fstab
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_INCREASES_COLDBOOT_TIMEOUT := true

# Display — 720x1280 portrait-native panel. Note the running system renders
# 1280x720 landscape; recovery uses the panel's own orientation.
TW_THEME := portrait_hdpi
DEVICE_RESOLUTION := 720x1280
DEVICE_SCREEN_WIDTH := 720
DEVICE_SCREEN_HEIGHT := 1280
BOARD_USE_FRAMEBUFFER_ALPHA_CHANNEL := true
TARGET_DISABLE_TRIPLE_BUFFERING := false

# Touchscreen is mounted rotated on this panel.
RECOVERY_TOUCHSCREEN_FLIP_X := true
RECOVERY_TOUCHSCREEN_FLIP_Y := true

# Storage
TW_INTERNAL_STORAGE_PATH := "/data/media"
TW_INTERNAL_STORAGE_MOUNT_POINT := "data"
TW_EXTERNAL_STORAGE_PATH := "/external_sd"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "external_sd"
RECOVERY_SDCARD_ON_DATA := true
TW_DEFAULT_EXTERNAL_STORAGE := true
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/class/android_usb/android0/f_mass_storage/lun/file

# Crypto — this device uses neither FDE nor FBE, which is also why TWRP needs no
# keymaster/gatekeeper HAL and therefore no vendor blobs at all.
TW_INCLUDE_CRYPTO := false
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
