## Secure Boot RPi4 with Nerves

The Raspberry Pi CM4 (and also, less conveniently, RPi4 and RPi400) have some
facilities for trusted/verified/secure boot. They call it Secure Boot.

To achieve it you need to use their tool
[usbboot](https://github.com/raspberrypi/usbboot/tree/master) to put initial
firmware on the storage device as well as flashing the bootloader with a cert.

Flashing the bootloader is outside the scope of Nerves. But you will need the
private key for that certificate to generate a `boot.sig` signature file for
the `boot.img` initial boot image that this scheme requires.

The boot procedure for the Pi4 will then be:

1. On power on, run `secure-boot-recovery` bootloader which has a burned-in
   certificate for which you have the private key. These are the Boot Keys.
   The Boot Public Key and Boot Private Key.
2. The secure boot loader will look for a `boot.img` and a `boot.sig`. It
   will verify that the `boot.sig` is a digest of `boot.img` signed by the
   Boot Private Key by checking the Boot Public Key stored in the OTP
   (One-Time Programmable) storage of the Pi4 processor.
3. Exactly what `boot.img` does is dictated by the kernel, drivers and mostly
   `config.txt` and `cmdline.txt` that are packaged in the image. In our case
   it will start an initramfs from the file `rootfs.cpio.zst`.
4. The initramfs will run `/init` which should do any setup required to verify
   the root filesystem and mount the `dm-verity` mapper.
   We include the `rootfs_public.pem` in `boot.img` to chain this together
   in a trustworthy fashion.
5. The initramfs will then switch_root into `/sbin/init_sh` which ensures some
   things are mounted before handing off to `/sbin/init` which is `erlinit`.
6. The rest is Nerves on top of trusted root filesystem.

