#!/bin/bash
source /vagrant/lib.sh

# install.
# see https://github.com/Foxboron/sbctl
go install -v github.com/foxboron/sbctl/cmd/sbctl@d1817b930dcf55701194aa173ffda77cd0030095 # 0.11 2023-03-25T14:15:15Z
