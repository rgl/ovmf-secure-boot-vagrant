#!/bin/bash
source /vagrant/lib.sh

# use go 1.19.
export GBB_PATH="$PWD/u-root-src"
export GOPATH="$HOME/go-1.19"
export PATH="$GBB_PATH:/usr/local/go-1.19/bin:$GOPATH/bin:$PATH"

# install.
# see https://u-root.org/
# see https://github.com/u-root/u-root
git clone https://github.com/u-root/u-root.git u-root-src
pushd u-root-src
git checkout 4dad982f78a72202985296afdfbc47c274ccc944 # v0.11.0 2023-02-02T08:20:08Z
go build
popd

# build a default initramfs.
rm -rf u-root && mkdir -p u-root && cd u-root
cat >uinit <<'UINIT_EOF'
#!/bin/bash
source /etc/profile

echo 'Mounting /boot/efi...'
mkdir -p /boot/efi
mount -t vfat /dev/sda1 /boot/efi

echo 'Mounts:'
cat /proc/mounts

echo 'Secure Boot Status:'
sbctl status

cat <<EOF
Useful commands:
Create secure boot keys: sbctl create-keys
Enroll secure boot keys: sbctl enroll-keys
Sign linux: sbctl sign /boot/efi/linux
Unmount: umount /boot/efi
Reboot the system: shutdown -r
Shutdown the system: shutdown
EOF
UINIT_EOF
chmod +x uinit
cat >loginshell <<EOF
#!/bin/bash
exec /bin/bash -i -l
EOF
chmod +x loginshell
cat >profile <<'EOF'
# export the ESP PATH environment variable to sbctl to known its mount point.
# NB this is needed because for some reason lsblk --json --output PARTTYPE,MOUNTPOINT,PTTYPE,FSTYPE
#    is only returning the MOUNTPOINT.
export ESP_PATH='/boot/efi'
PS1='\w\$ '
alias l='ls -laF'
EOF
# NB even though we are including the cmds/exp/bootvars command, it does not
#    work due to https://github.com/u-root/u-root/issues/2082.
# NB we are copying the kernel modules to /modules instead of /lib/modules
#    because we want to manually load them for testing purposes (keep in mind
#    that the modules from /lib/modules are automatically loaded).
u-root \
    -o initramfs.cpio \
    -uinitcmd /uinit \
    -defaultsh /loginshell \
    -files uinit:uinit \
    -files loginshell:loginshell \
    -files profile:etc/profile \
    -files "$(ls /vagrant/tmp/linux-modules/lib/modules/*/kernel/kernel/configs.ko):modules/configs.ko" \
    -files /bin/bash \
    -files /usr/bin/lsblk \
    -files /usr/bin/lspci \
    -files /usr/share/misc/pci.ids \
    -files ~/go/bin/efianalyze:usr/local/bin/efianalyze \
    -files ~/go/bin/sbctl:usr/local/bin/sbctl \
    minimal \
    github.com/u-root/u-root/cmds/exp/bootvars
cpio --list --numeric-uid-gid --verbose <initramfs.cpio
# NB to abort qemu press ctrl+a, c then enter the quit command.
# NB to poweroff the vm enter the shutdown command.
#qemu-system-x86_64 -kernel "/boot/vmlinuz-$(uname -r)" -initrd initramfs.cpio -nographic -append console=ttyS0
#qemu-system-x86_64 -kernel "/boot/vmlinuz-$(uname -r)" -initrd initramfs.cpio -append vga=786

# create a disk image.
qemu-img create -f qcow2 boot.qcow2 150M
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 boot.qcow2
sudo parted --script /dev/nbd0 mklabel gpt
sudo parted --script /dev/nbd0 mkpart esp fat32 1MiB 100MiB
sudo parted --script /dev/nbd0 set 1 esp on
sudo parted --script /dev/nbd0 set 1 boot on
sudo parted --script /dev/nbd0 mkpart root ext4 100MiB 100%
sudo parted --script /dev/nbd0 print
sudo mkfs -t vfat -n ESP /dev/nbd0p1
sudo mkfs -t ext4 -L ROOT /dev/nbd0p2
sudo mkdir -p /mnt/ovmf/{esp,root}
sudo mount /dev/nbd0p1 /mnt/ovmf/esp
sudo mount /dev/nbd0p2 /mnt/ovmf/root
sudo install /vagrant/tmp/*.efi /mnt/ovmf/esp
cat initramfs.cpio | (cd /mnt/ovmf/root && sudo cpio -idv --no-absolute-filenames)
sudo install /vagrant/tmp/linux /mnt/ovmf/esp
sudo bash -c 'cat >/mnt/ovmf/esp/startup.nsh' <<'EOF'
# show the UEFI versions.
ver

# show the memory map.
memmap

# show the disks and filesystems.
map

# show the environment variables.
set

# show all UEFI variables.
#dmpstore -all

# show the secure boot platform status.
# possible values:
#   00: User Mode
#   01: Setup Mode
setvar -guid 8be4df61-93ca-11d2-aa0d-00e098032b8c SetupMode

# show the secure boot status.
# possible values:
#   00: Disabled
#   01: Enabled
setvar -guid 8be4df61-93ca-11d2-aa0d-00e098032b8c SecureBoot

# show the secure boot key stores.
setvar -guid 8be4df61-93ca-11d2-aa0d-00e098032b8c PK   # Platform Key (PK).
setvar -guid 8be4df61-93ca-11d2-aa0d-00e098032b8c KEK  # Key Exchange Key (KEK).
setvar -guid d719b2cb-3d3a-4596-a3bc-dad00e67656f db   # Signature Database (DB); aka Allow list database.
setvar -guid d719b2cb-3d3a-4596-a3bc-dad00e67656f dbx  # Forbidden Signature Database (DBX); ala Deny list database.

# show boot entries.
bcfg boot dump -v

# execute linux.
fs0:
linux mitigations=off console=ttyS0 debug earlyprintk=serial rw root=/dev/sda2 init=/init
EOF
df -h /mnt/ovmf/esp
df -h /mnt/ovmf/root
sudo umount /mnt/ovmf/esp
sudo umount /mnt/ovmf/root
sudo qemu-nbd --disconnect /dev/nbd0

# create the launch script.
# NB to start from scratch, delete the test sub-directory before executing run.sh.
cat >run.sh <<'EOF'
#!/bin/bash
set -euxo pipefail
mkdir -p test && cd test
if [ ! -f test-ovmf-code-amd64.fd ]; then
    install -m 440 ../OVMF_CODE.fd test-ovmf-code-amd64.fd
fi
if [ ! -f test-ovmf-vars-amd64.fd ]; then
    install -m 660 ../OVMF_VARS.fd test-ovmf-vars-amd64.fd
fi
if [ ! -f test-boot.qcow2 ]; then
    install -m 660 ../boot.qcow2 test-boot.qcow2
    # NB to use the ubuntu image instead, uncomment the following line.
    #qemu-img create -f qcow2 -b ~/.vagrant.d/boxes/ubuntu-22.04-uefi-amd64/0.0.0/libvirt/box_0.img test-boot.qcow2
    qemu-img info test-boot.qcow2
fi
# NB replace -nographic with -vga qxl to enable the GUI console.
qemu-system-x86_64 \
  -name amd64 \
  -no-user-config \
  -nodefaults \
  -nographic \
  -machine q35,accel=kvm,smm=on \
  -cpu host \
  -smp 2 \
  -m 2g \
  -k pt \
  -boot menu=on,strict=on \
  -chardev stdio,mux=on,signal=off,id=char0 \
  -mon chardev=char0,mode=readline \
  -serial chardev:char0 \
  -fw_cfg name=opt/org.tianocore/IPv4PXESupport,string=n \
  -fw_cfg name=opt/org.tianocore/IPv6PXESupport,string=n \
  -global ICH9-LPC.disable_s3=1 \
  -global ICH9-LPC.disable_s4=1 \
  -global driver=cfi.pflash01,property=secure,value=on \
  -drive if=pflash,unit=0,file=test-ovmf-code-amd64.fd,format=raw,readonly=on \
  -drive if=pflash,unit=1,file=test-ovmf-vars-amd64.fd,format=raw \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-pci,rng=rng0 \
  -debugcon file:ovmf.log \
  -global isa-debugcon.iobase=0x402 \
  -qmp unix:amd64.socket,server,nowait \
  -device virtio-scsi-pci,id=scsi0 \
  -drive if=none,file=test-boot.qcow2,format=qcow2,id=hd0 \
  -device scsi-hd,drive=hd0
EOF
chmod +x run.sh

# copy to the host.
install -d /vagrant/tmp
install -m 444 boot.qcow2 /vagrant/tmp
install -m 555 run.sh /vagrant/tmp
