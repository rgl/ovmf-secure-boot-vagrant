#!/bin/bash
source /vagrant/lib.sh

# install.
# see https://github.com/Foxboron/go-uefi
go get -v github.com/foxboron/go-uefi/cmd/efianalyze@3a44878e0db98c03f38138a26c4b56ed219f2949 # 2021-07-07T12:36:20Z
