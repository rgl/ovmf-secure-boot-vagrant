#!/bin/bash
source /vagrant/lib.sh

# install.
# see https://github.com/Foxboron/go-uefi
go install -v github.com/foxboron/go-uefi/cmd/efianalyze@6b0ee85df4cd4bfe24a2bdf2120f0f9ffe029841 # 2021-09-29T17:09:05Z
