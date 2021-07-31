#!/bin/bash
source /vagrant/lib.sh

# install go.
# see https://golang.org/dl/
# see https://golang.org/doc/install
artifact_url=https://golang.org/dl/go1.16.6.linux-amd64.tar.gz
artifact_sha=be333ef18b3016e9d7cb7b1ff1fdb0cac800ca0be4cf2290fe613b3d069dfe0d
artifact_path="/tmp/$(basename $artifact_url)"
wget -qO $artifact_path $artifact_url
if [ "$(sha256sum $artifact_path | awk '{print $1}')" != "$artifact_sha" ]; then
    echo "downloaded $artifact_url failed the checksum verification"
    exit 1
fi
rm -rf /usr/local/go
install -d /usr/local/go
tar xf $artifact_path -C /usr/local/go --strip-components 1
rm $artifact_path

# add go to all users path.
cat >/etc/profile.d/go.sh <<'EOF'
#[[ "$-" != *i* ]] && return
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"
EOF
