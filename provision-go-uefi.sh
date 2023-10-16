#!/bin/bash
source /vagrant/lib.sh

# install.
# see https://github.com/Foxboron/go-uefi
go install -v github.com/foxboron/go-uefi/cmd/efianalyze@18b9ba9cd4c3e6ff3f8ac11a3102b1ec8b85fe51 # 2023-08-08T20:18:20Z
