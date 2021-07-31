#!/bin/bash
source /vagrant/lib.sh

# install dependencies.
sudo apt-get install -y sbsigntool

# install.
# see https://github.com/Foxboron/sbctl
# TODO lock the version.
go get -v github.com/Foxboron/sbctl/cmd/sbctl
