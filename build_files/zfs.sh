#!/bin/sh

set -euo pipefail

dnf5 install -y https://zfsonlinux.org/fedora/zfs-release-2-8$(rpm --eval "%{dist}").noarch.rpm
dnf5 install -y dkms zfs
dkms install zfs/$(basename $(find /usr/src -name 'zfs-*' -maxdepth 1 | tail -1 | sed -e 's!-!/!g')) --kernelsourcedir $(find /usr/src/kernels -maxdepth 1 | tail -1) -k $(basename $(find /usr/src/kernels -maxdepth 1 | tail -1))
systemctl enable zfs.target zfs-import.target make-zfs.service

# create the pool path in advance since the filesystem will be read-only
mkdir -p /trunk
