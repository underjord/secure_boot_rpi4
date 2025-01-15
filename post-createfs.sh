#!/bin/sh

set -e

FWUP_CONFIG=$NERVES_DEFCONFIG_DIR/fwup.conf

# To use Secure Boot make sure to set the following env vars:
# BOOT_PRIVATE_KEY="../mybootkey_private.pem" # Used to sign `boot.img`
# ROOTFS_PUBLIC_KEY="../myrootkey_public.pem" # Used to verify signed root hash on root fs
if [[ -z "${BOOT_PRIVATE_KEY}"]]; then
	./secure_boot/generate_boot_img.sh
fi

# Run the common post-image processing for nerves
$BR2_EXTERNAL_NERVES_PATH/board/nerves-common/post-createfs.sh $TARGET_DIR $FWUP_CONFIG
