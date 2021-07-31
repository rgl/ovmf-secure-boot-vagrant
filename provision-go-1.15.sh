#!/bin/bash
source /vagrant/lib.sh

# install go.
# see https://golang.org/dl/
# see https://golang.org/doc/install
# NB u-root does not work with go 1.16.
# TODO use go 1.16 when https://github.com/u-root/u-root/issues/1859 is fixed.
artifact_url=https://golang.org/dl/go1.15.14.linux-amd64.tar.gz
artifact_sha=6f5410c113b803f437d7a1ee6f8f124100e536cc7361920f7e640fedf7add72d
artifact_path="/tmp/$(basename $artifact_url)"
wget -qO $artifact_path $artifact_url
if [ "$(sha256sum $artifact_path | awk '{print $1}')" != "$artifact_sha" ]; then
    echo "downloaded $artifact_url failed the checksum verification"
    exit 1
fi
rm -rf /usr/local/go-1.15
install -d /usr/local/go-1.15
tar xf $artifact_path -C /usr/local/go-1.15 --strip-components 1
rm $artifact_path
