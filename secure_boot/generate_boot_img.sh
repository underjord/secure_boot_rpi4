#!/bin/sh

set -e

echo "Setting up RPi4 for Secure Boot using key: ${BOOT_PRIVATE_KEY}"

# Generate boot.img and sign it as boot.sig
BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_BOOT_CFG="${NERVES_DEFCONFIG_DIR}/secure_boot/boot_img.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"
FILES_DIR="$(mktemp -d)"
# Copy the system files, we want many, but need to replace some
cp -r $BINARIES_DIR/* $FILES_DIR/

cp "${NERVES_DEFCONFIG_DIR}/secure_boot/boot_img/config.txt" \
   "${FILES_DIR}/config.txt"
cp "${NERVES_DEFCONFIG_DIR}/secure_boot/boot_img/cmdline.txt" \
   "${FILES_DIR}/cmdline.txt"

# Store public key for root fileystem verification inside the
# boot.img that we will sign using the boot private key
cp $ROOTFS_PUBLIC_KEY $FILES_DIR/rootfs_public.pem

rm -f "${FILES_DIR}/boot.vfat" "${FILES_DIR}/boot.sig"

# start.elf supports compressed 64-bit kernel images.
if [ -f ${FILES_DIR}/Image ]; then
rm -f ${FILES_DIR}/zImage ${FILES_DIR}/kernel8.img.gz
gzip ${FILES_DIR}/Image
mv ${FILES_DIR}/Image.gz ${FILES_DIR}/zImage
fi

# Use the VFAT image to build boot.img
rm -rf "${GENIMAGE_TMP}"

echo "genimage --rootpath \"${ROOTPATH_TMP}\" \\"
echo "--tmppath \"${GENIMAGE_TMP}\" --inputpath \"${FILES_DIR}\" \\"
echo "--outputpath \"${BINARIES_DIR}\" --config \"${GENIMAGE_BOOT_CFG}\""

genimage \
    --rootpath "${ROOTPATH_TMP}"   \
    --tmppath "${GENIMAGE_TMP}"    \
    --inputpath "${FILES_DIR}"  \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_BOOT_CFG}"

KEY_ARGS="-k ${BOOT_PRIVATE_KEY}"
rpi-eeprom-digest -i "${BINARIES_DIR}/boot.img" -o "${BINARIES_DIR}/boot.sig" ${KEY_ARGS}