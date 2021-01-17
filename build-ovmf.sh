#!/bin/bash
export WORKSPACE=$HOME/edk2
source $WORKSPACE/edksetup.sh
set -euxo pipefail

cd $WORKSPACE

# build.
# TODO TPM_ENABLE=TRUE
# TODO TPM_CONFIG_ENABLE=TRUE
# TODO NETWORK_TLS_ENABLE=TRUE
# TODO increase the logging level with --pcd gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x8000004F and use # DEBUG_VARIABLE  0x00000100  // Variable ?
# see https://github.com/tianocore/edk2/blob/master/OvmfPkg/README
NUM_CPUS=$((`getconf _NPROCESSORS_ONLN` + 2))
build \
    -p OvmfPkg/OvmfPkgX64.dsc \
    -a X64 \
    -t GCC5 \
    -b DEBUG \
    -n $NUM_CPUS \
    -D SECURE_BOOT_ENABLE=TRUE \
    -D SMM_REQUIRE=TRUE \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"rgl" \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"rgl uefi firmware"

# copy to the host.
# NB we also copy the Shell.efi file because its easier to use it
#    as a boot option. e.g. to add it as the last boot option to
#    reboot the system when all the other options have failed.
mkdir -p /vagrant/tmp
cp Build/OvmfX64/DEBUG_GCC5/FV/OVMF*.fd /vagrant/tmp/
cp Build/OvmfX64/DEBUG_GCC5/X64/Shell.efi /vagrant/tmp/
cp Build/OvmfX64/DEBUG_GCC5/X64/UiApp.efi /vagrant/tmp/
ls -laF /vagrant/tmp/{OVMF*.fd,Shell.efi,UiApp.efi}
