#!/bin/bash
source /vagrant/lib.sh

# install.
# see https://github.com/0xef53/qmp-shell
go get -v github.com/0xef53/qmp-shell@582a5ac813191044ae2930ad278b179235ab6d7c # v2.0.1 2020-06-20T09:35:43Z

# copy to the host.
install -d /vagrant/tmp
install -m 555 ~/go/bin/qmp-shell /vagrant/tmp
