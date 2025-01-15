#!/bin/sh

set -e

FWUP_CONFIG=$NERVES_DEFCONFIG_DIR/fwup.conf

# Modify this for your custom system that needs Secure Boot
# Private key that matches the CM4's burned-in bootloader certificate 
#export BOOT_PRIVATE_KEY=""
# Public key that matches the private key used for 
#export ROOTFS_PUBLIC_KEY=""
if [[ -z "${BOOT_PRIVATE_KEY}"]]; then
	./secure_boot/generate_boot_image.sh
fi

# Run the common post-image processing for nerves
$BR2_EXTERNAL_NERVES_PATH/board/nerves-common/post-createfs.sh $TARGET_DIR $FWUP_CONFIG
