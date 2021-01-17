#!/bin/bash
set -euxo pipefail

# install go.
# see https://golang.org/dl/
# see https://golang.org/doc/install
artifact_url=https://golang.org/dl/go1.15.6.linux-amd64.tar.gz
artifact_sha=3918e6cc85e7eaaa6f859f1bdbaac772e7a825b0eb423c63d3ae68b21f84b844
artifact_path="/tmp/$(basename $artifact_url)"
wget -qO $artifact_path $artifact_url
if [ "$(sha256sum $artifact_path | awk '{print $1}')" != "$artifact_sha" ]; then
    echo "downloaded $artifact_url failed the checksum verification"
    exit 1
fi
tar xf $artifact_path -C /usr/local
rm $artifact_path

# add go to all users path.
cat >/etc/profile.d/go.sh <<'EOF'
#[[ "$-" != *i* ]] && return
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"
EOF
