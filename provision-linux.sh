#!/bin/bash
source /vagrant/lib.sh

# go home.
cd ~

# install dependencies.
sudo apt-get install -y bc bison flex libssl-dev make libc6-dev libncurses5-dev libelf-dev

# get the linux kernel source code.
if [ ! -d linux ]; then
    linux_url='https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.258.tar.xz'
    linux_path="$(basename $linux_url)"
    wget -qO $linux_path $linux_url
    mkdir linux
    tar xf $linux_path -C linux --strip-components 1
fi

# build.
# see make help
cd linux
make x86_64_defconfig
make kvmconfig # or make kvm_guest.config # this comes from ./kernel/configs/kvm_guest.config
# TODO evaluate EFI_BOOTLOADER_CONTROL
cat >rgl.config <<'EOF'
CONFIG_LOCALVERSION="-rgl"
# CONFIG_MODULES is not set
# CONFIG_IA32_EMULATION is not set
# CONFIG_MAGIC_SYSRQ is not set
# CONFIG_VIRTIO_PCI_LEGACY is not set
# CONFIG_EFI_VARS is not set
# CONFIG_EFI_MIXED is not set
CONFIG_SECURITY_LOCKDOWN_LSM=y
CONFIG_SECURITY_LOCKDOWN_LSM_EARLY=y
CONFIG_LOCK_DOWN_KERNEL_FORCE_CONFIDENTIALITY=y
CONFIG_HW_RANDOM_VIRTIO=y
CONFIG_FW_CFG_SYSFS=y
EOF
./scripts/kconfig/merge_config.sh -n .config rgl.config
cat >rgl-modules.config <<'EOF'
CONFIG_MODULES=y
CONFIG_MODULE_SIG_ALL=y
CONFIG_MODULE_SIG_SHA256=y
CONFIG_IKCONFIG=m
CONFIG_IKCONFIG_PROC=y
EOF
./scripts/kconfig/merge_config.sh -n .config rgl-modules.config
time make -j $(nproc) bzImage # see arch/x86/Makefile
time make -j $(nproc) modules
rm -rf /vagrant/tmp/linux-modules
# NB since we are using CONFIG_MODULE_SIG_ALL the modules will be signed by
#    the kernel build time autogenerated key file at modules_install time.
# NB the public key of the signing key is bundled with the kernel image,
#    and the kernel will only load modules signed by it.
# see https://www.kernel.org/doc/html/v5.4/admin-guide/module-signing.html
time make INSTALL_MOD_PATH=/vagrant/tmp/linux-modules modules_install
# NB to abort qemu press ctrl+a, c then enter the quit command.
#qemu-system-x86_64 -kernel arch/x86/boot/bzImage -nographic -append console=ttyS0
#qemu-system-x86_64 -kernel arch/x86/boot/bzImage -append vga=786

# copy to host.
install arch/x86/boot/bzImage /vagrant/tmp/linux
install .config /vagrant/tmp/linux.config
