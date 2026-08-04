# TWRP product definition for the GPD XD+ (xdplus).
#
# Codename note: the OEM codename is "xds" and the 2018-era community trees used
# "gpd_en". The recovery that ships on this device reports ro.product.device and
# ro.omni.device as "xdplus", so that is what this tree uses.

PRODUCT_RELEASE_NAME := xdplus

$(call inherit-product, $(SRC_TARGET_DIR)/product/embedded.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# TWRP itself
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_DEVICE := xdplus
PRODUCT_NAME := twrp_xdplus
PRODUCT_BRAND := GPD
PRODUCT_MODEL := XD Plus
PRODUCT_MANUFACTURER := GPD
