#!/bin/bash
set -euxo pipefail

# install.
# see https://github.com/0xef53/qmp-shell
# TODO lock the version.
go get -v github.com/0xef53/qmp-shell

# copy to the host.
install -d /vagrant/tmp
install -m 555 ~/go/bin/qmp-shell /vagrant/tmp
