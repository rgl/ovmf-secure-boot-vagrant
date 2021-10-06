#!/bin/bash
source /vagrant/lib.sh

# install.
# see https://github.com/Foxboron/sbctl
go install -v github.com/foxboron/sbctl/cmd/sbctl@bedb8e8c8378c35195326e7fffa5f86b978662fd # 2021-09-05T13:33:17Z
