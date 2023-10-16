#!/bin/bash
source /vagrant/lib.sh


#
# prevent apt-get et al from asking questions.

echo 'Defaults env_keep += "DEBIAN_FRONTEND"' >/etc/sudoers.d/env_keep_apt
chmod 440 /etc/sudoers.d/env_keep_apt
export DEBIAN_FRONTEND=noninteractive


#
# make sure the package index cache is up-to-date before installing anything.

apt-get update


#
# expand the root partition.

apt-get install -y --no-install-recommends parted
partition_device="$(findmnt -no SOURCE /)"
partition_number="$(echo "$partition_device" | perl -ne '/(\d+)$/ && print $1')"
disk_device="$(echo "$partition_device" | perl -ne '/(.+?)\d+$/ && print $1')"
gdisk "$disk_device" <<EOF
v
w
Y
Y
EOF
parted ---pretend-input-tty "$disk_device" <<EOF
resizepart $partition_number 100%
yes
EOF
resize2fs "$partition_device"


#
# install vim.

apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF


#
# configure the shell.

cat >/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

cat >~/.bash_history <<'EOF'
EOF

# configure the vagrant user home.
su vagrant -c bash <<'EOF-VAGRANT'
set -euxo pipefail

cat >~/.bash_history <<'EOF'
EOF
EOF-VAGRANT

# install and configure git.
apt-get install -y git-core
su vagrant -c bash <<'EOF'
set -eux
git config --global user.email 'rgl@ruilopes.com'
git config --global user.name 'Rui Lopes'
git config --global push.default simple
git config --global core.autocrlf false
EOF

# install qemu.
apt-get install -y qemu-system-x86
