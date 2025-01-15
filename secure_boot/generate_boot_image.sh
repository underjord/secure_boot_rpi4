#!/bin/sh

set -e

echo "Setting up RPi4 for Secure Boot using key: ${BOOT_PRIVATE_KEY}"

# Generate boot.img and sign it as boot.sig
BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_BOOT_CFG="${BOARD_DIR}/secure_boot/boot_image.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

# Store public key for root fileystem verification inside the
# boot.img that we will sign using the boot private key
cp $ROOTFS_PUBLIC_KEY $BINARIES_DIR/roofs_public.pem

rm -f "${BINARIES_DIR}/boot.vfat" "${BINARIES_DIR}/boot.sig"

# start.elf supports compressed 64-bit kernel images.
if [ -f ${BINARIES_DIR}/Image ]; then
rm -f ${BINARIES_DIR}/zImage ${BINARIES_DIR}/kernel8.img.gz
gzip ${BINARIES_DIR}/Image
mv ${BINARIES_DIR}/Image.gz ${BINARIES_DIR}/zImage
fi

# Use the VFAT image to build boot.img
rm -rf "${GENIMAGE_TMP}"
echo "genimage --rootpath \"${ROOTPATH_TMP}\" --tmppath \"${GENIMAGE_TMP}\" --inputpath \"${BINARIES_DIR}\" --outputpath \"${BINARIES_DIR}\" --config \"${GENIMAGE_BOOT_CFG}\""

genimage \
    --rootpath "${ROOTPATH_TMP}"   \
    --tmppath "${GENIMAGE_TMP}"    \
    --inputpath "${BINARIES_DIR}"  \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_BOOT_CFG}"

KEY_ARGS="-k ${BOOT_PRIVATE_KEY}"
rpi-eeprom-digest -i "${BINARIES_DIR}/boot.img" -o "${BINARIES_DIR}/boot.sig" ${KEY_ARGS}
cp "${BINARIES_DIR}/boot.img" "${NERVES_DEFCONFIG_DIR}/.boot/boot.img"
cp "${BINARIES_DIR}/boot.sig" "${NERVES_DEFCONFIG_DIR}/.boot/boot.sig"