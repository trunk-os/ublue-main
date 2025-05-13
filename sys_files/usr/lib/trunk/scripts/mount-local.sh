#!/bin/bash

# NOTE: this was designed to overlay zfs over /etc and /var to keep changes on local storage
# it is not currently operational and therefore is not enabled; I am keeping it
# in here to make it easy to recover when it's ready to be modified.
# 
# DO NOT USE THIS SCRIPT.

set -xeo pipefail

POOL="${POOL:-trunk}"
DEBUG="${DEBUG:-}"

. $(dirname $0)/zfs-debug.sh

zfs_create_if() {
  v=""
  if [ "x$2" != "x" ]
  then
    v="-V $2"
  fi

  (zfs list | grep -qE "^$1 ") || zfs create $v $1
  if [ "x$2" != "x" ]
  then
    if [ "x$DEBUG" = "x" ]
    then
      echo -n "Waiting for device to appear..."
      while ! test -e /dev/zvol/$1
      do
        echo -n "."
        sleep 1
      done
      echo "done."

      `which mkfs.ext4` /dev/zvol/$1
    else
      echo "$(which mkfs.ext4) /dev/zvol/$1"
    fi
  fi
}

prep_overlay() {
  mount /dev/zvol/${POOL}/internal/$1 /config/$1
  mkdir -p /config/$1/work /config/$1/data
}

# FIXME should probably cap this as some upper bound; just not sure what that should be
pool_size=$(zfs list -p | grep -E "^${POOL} " | awk '{ print $2 }')
etc_size=$(($(($pool_size / 100)) * 5))
var_size=$(($(($pool_size / 100)) * 10))

zfs_create_if ${POOL}/internal
zfs_create_if ${POOL}/internal/etc $(printf "%dM" $etc_size)
zfs_create_if ${POOL}/internal/var $(printf "%dM" $var_size)

for overlay in etc var
do
  prep_overlay $overlay
done

etc_lower_dirs=""

# find lower paths
for dir in $(find /sysroot/ostree/deploy/default/deploy -maxdepth 1 -type d | tail -n +2 | sort)
do
  if [ -d $dir/etc ]
  then
    if [ "x$etc_lower_dirs" = "x" ]
    then
      etc_lower_dirs=$dir/etc
    else
      etc_lower_dirs="$etc_lower_dirs:$dir/etc"
    fi
  fi
done

# establish two overlays for /etc and /var, attach to zfs internal datasets
mount -t overlay -o lowerdir=$etc_lower_dirs,upperdir=/config/etc/data,workdir=/config/etc/work /config/merged/etc /config/merged/etc
mount -t overlay -o lowerdir=/sysroot/ostree/deploy/default/var,upperdir=/config/var/data,workdir=/config/var/work /config/merged/var /config/merged/var

#umount -l /etc
#umount -l /var
#
#mount --bind /config/merged/etc /etc
#mount --bind /config/merged/var /var
