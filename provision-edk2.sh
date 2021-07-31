#!/bin/bash
source /vagrant/lib.sh

# install the dependencies.
apt-get install -y \
    acpica-tools \
    python3-distutils \
    uuid-dev \
    build-essential \
    nasm \
    dos2unix
ln -s /usr/bin/python{3,} # symlink python to python3.

# build the base edk2 tools.
su vagrant -c bash <<'EOF'
set -euxo pipefail

# clone the edk2 repo.
git clone https://github.com/tianocore/edk2.git edk2
cd edk2
git checkout edk2-stable202011
git submodule update --init --recursive

# build the base edk2 tools.
time make -C BaseTools
EOF
