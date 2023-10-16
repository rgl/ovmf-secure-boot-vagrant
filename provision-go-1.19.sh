#!/bin/bash
source /vagrant/lib.sh

# install go.
# see https://go.dev/dl/
# see https://go.dev/doc/install
# NB u-root does not work with go 1.20.
artifact_url=https://go.dev/dl/go1.19.13.linux-amd64.tar.gz
artifact_sha=4643d4c29c55f53fa0349367d7f1bb5ca554ea6ef528c146825b0f8464e2e668
artifact_path="/tmp/$(basename $artifact_url)"
wget -qO $artifact_path $artifact_url
if [ "$(sha256sum $artifact_path | awk '{print $1}')" != "$artifact_sha" ]; then
    echo "downloaded $artifact_url failed the checksum verification"
    exit 1
fi
rm -rf /usr/local/go-1.19
install -d /usr/local/go-1.19
tar xf $artifact_path -C /usr/local/go-1.19 --strip-components 1
rm $artifact_path
