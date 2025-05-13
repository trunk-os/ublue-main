#!/bin/bash

set -euo pipefail

POOL="${POOL:-trunk}"
DEBUG="${DEBUG:-}"

. $(dirname $0)/zfs-debug.sh

# this just searches for a specific syntax in the mount -l output and returns
# the disk for that path. It's deliberately looser than checking proc or using
# other mount commands, (or reading fstab, etc) so it can match prefixes.
getmount() {
  mount -l | grep "on $1 type" | awk '{ print $1 }'
}

# determine if the path we are looking at is related to the boot or root
# (running) filesystem. Since this can get wonky and we don't want to enumerate
# every possible combination, prefer paths that start with /boot, then look for
# atomic installs by checking for /sysroot, and finally check / if they're not
# found, as / will probably be a real filesystem. (In atomic's case it is not)
onroot() {
  out="$(getmount /boot)"
  if [ "$?" -ne 0 ]
  then
    out="$(getmount /sysroot)"
  fi
  if [ "$?" -ne 0 ]
  then
    out="$(getmount /)"
  fi

  echo "$out" | grep -qE "^/dev/$1"
  return $?
}

# check if the pool already exists before provisioning it. If the pool is
# already imported, just exit. If not, try to import it and ensure it imported
# correctly, then exit. Otherwise, continue with the script.
if zpool list | grep -qE "^$POOL"
then
  exit 0
elif zpool import $POOL && (zpool list | grep -qE "^$POOL")
then
  exit 0
fi

# create a list of free disks that can be used by ZFS
free_disks=""

# collect swap devices (they don't appear in mount)
swap="$(for disk in `swapon | awk '{ print $1 }' | tail -n +2`; do basename $disk; done)"
# number of disks (used for selecting raid strategy later)
count=0

# enumerate known block devices created by the kernel
# FIXME we need to enumerate disks, not block devices; this will break sooner or later
for disk in /sys/block/*
do
  # if this device is swap, skip it
  found=""
  for swap in $swap 
  do
    if echo $swap | grep -q $(basename $disk)
    then
      found=1
    fi
  done

  if [ "x$found" != "x" ]
  then
    continue
  fi

  # if we're not currently using it
  if ! onroot $(basename $disk)
  then
    # and it actually exists (isn't removed)
    if ! cat $disk/events | grep -q media_change
    then
      # add to the free disks list and increment the count
      free_disks="$free_disks /dev/$(basename $disk)"
      count=$(($count + 1))
    fi
  fi
done

if [ "$count" -eq 0 ]
then
  if [ "x$DEBUG" = "x" ]
  then
    shutdown -h now
  else
    echo "Would have shutdown machine; no extra disks attached"
  fi
elif [ "$count" -eq 1 ]
then
  zpool create trunk $free_disks
elif [ "$count" -eq 2 ]
then
  zpool create trunk mirror $free_disks
else
  zpool create trunk raidz $free_disks
fi
