# About

This is a [Vagrant](https://www.vagrantup.com/) Environment for setting up
the [OVMF UEFI EDK2](https://github.com/tianocore/edk2) environment to play
with [UEFI Secure Boot](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface#SECURE-BOOT).

## Usage

Install the [base Ubuntu 20.04 UEFI box](https://github.com/rgl/ubuntu-vagrant).

Start the environment:

```bash
# NB in my machine this takes ~30m to complete.
time vagrant up --provider=libvirt --no-destroy-on-error --no-tty
```

Start ovmf/linux/u-boot in a test vm:

```bash
cd tmp
./run.sh
```

Verify that the platform is in Setup Mode:

```bash
sbctl status
```

It must output:

```plain
==> WARNING: Setup Mode: Enabled
==> WARNING: Secure Boot: Disabled
```

Create our own Platform Key (PK), Key Exchange Key (KEK), and Code Signing CAs:

```bash
# NB this internally uses sbvarsign and sbvarsign commands.
# see https://github.com/Foxboron/sbctl/blob/fda4f2c1efd801cd04fb52923afcdb34baa42369/keys.go#L92-L100
# see https://github.com/Foxboron/sbctl/blob/fda4f2c1efd801cd04fb52923afcdb34baa42369/keys.go#L102-L110
sbctl create-keys
```

It should something alike:

```bash
==> Creating secure boot keys...
  -> Created UUID 52364904-f16c-4e09-b9eb-57907da8302a...
==> Create EFI signature list /usr/share/secureboot/keys/PK/PK.der.esl...
==> Signing /usr/share/secureboot/keys/PK/PK.der.esl with /usr/share/secureboot/keys/PK/PK.key...
==> Create EFI signature list /usr/share/secureboot/keys/KEK/KEK.der.esl...
==> Signing /usr/share/secureboot/keys/KEK/KEK.der.esl with /usr/share/secureboot/keys/PK/PK.key...
==> Create EFI signature list /usr/share/secureboot/keys/db/db.der.esl...
==> Signing /usr/share/secureboot/keys/db/db.der.esl with /usr/share/secureboot/keys/KEK/KEK.key...
```

In more detail, this created all these files:

```bash
# find -type f /usr/share/secureboot/keys
/usr/share/secureboot/keys/KEK/KEK.auth
/usr/share/secureboot/keys/KEK/KEK.der
/usr/share/secureboot/keys/KEK/KEK.der.esl
/usr/share/secureboot/keys/KEK/KEK.key
/usr/share/secureboot/keys/KEK/KEK.pem
/usr/share/secureboot/keys/PK/PK.auth
/usr/share/secureboot/keys/PK/PK.der
/usr/share/secureboot/keys/PK/PK.der.esl
/usr/share/secureboot/keys/PK/PK.key
/usr/share/secureboot/keys/PK/PK.pem
/usr/share/secureboot/keys/db/db.auth
/usr/share/secureboot/keys/db/db.der
/usr/share/secureboot/keys/db/db.der.esl
/usr/share/secureboot/keys/db/db.key
/usr/share/secureboot/keys/db/db.pem
```

Enroll the keys with the firmware:

```bash
# NB internally this will write the EFI variables by calling:
#       sbkeysync --pk --verbose --keystore /usr/share/secureboot/keys
# see https://github.com/Foxboron/sbctl/blob/fda4f2c1efd801cd04fb52923afcdb34baa42369/keys.go#L114-L115
sbctl enroll-keys
```

It should display something alike:

```plain
==> Syncing /usr/share/secureboot/keys to EFI variables...
==> Synced keys!
```

Verify that the platform is now out of Setup Mode:

```bash
sbctl status
```

It must output:

```plain
==> Setup Mode: Disabled
==> WARNING: Secure Boot: Disabled
```

Sign the linux efi application:

```bash
sbctl sign /boot/efi/linux
```

It should output something alike:

```plain
-> Signing /boot/efi/linux...
```

Reboot the system:

```bash
umount /boot/efi
shutdown -r
```

After boot, verify that the platform is now in Secure Boot mode:

```bash
sbctl status
```

It must output:

```plain
==> Setup Mode: Disabled
==> Secure Boot: Enabled
```

Test loading a kernel module:

```bash
insmod /modules/configs.ko
```

It must not return any output nor error.

And that's pretty much how you test drive Secure Boot in OVMF.

## QEMU VM device tree

You can see all the qemu devices status by running the following command in another shell:

```bash
cd tmp
echo info qtree | ./qmp-shell -H ./test/amd64.socket
```

## Reference

* [Unified Extensible Firmware Interface (UEFI)](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface).
* [UEFI Forum](http://www.uefi.org/).
* [EDK II (aka edk2): UEFI Reference Implementation ](https://github.com/tianocore/edk2).
* [EDK II `bcfg boot dump` source code](https://github.com/tianocore/edk2/blob/976d0353a6ce48149039849b52bb67527be5b580/ShellPkg/Library/UefiShellBcfgCommandLib/UefiShellBcfgCommandLib.c#L1301).
* [UefiToolsPkg](https://github.com/andreiw/UefiToolsPkg) set of UEFI tools.
  * These are useful on their own and as C source based UEFI application examples.
