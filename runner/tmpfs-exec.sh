#!/usr/bin/env bash

set -ae

[[ $VERBOSE =~ true|True|yes|Yes|on|On|1 ]] && set -x

# these tmpfs mounts need the executable bit set
mount -o remount,rw,exec tmpfs /tmp
mount -o remount,rw,exec tmpfs /run

# create tmpfs overlays for some directories that need to be writable
# but should not persist container restarts
for dir in /home/runner
do
    # unmount any existing binds
    umount ${dir} || true
    # create mountpoint for a new tmpfs
    mkdir -p "${dir}.tmpfs"
    # create the tmpfs with execute permissions
    mount -t tmpfs -o rw,exec tmpfs "${dir}.tmpfs"
    # copy the contents of the original directory to the tmpfs
    cp -av "${dir}"/* "${dir}.tmpfs"
    # bind mount the tmpfs over the original
    mount --bind "${dir}.tmpfs" "${dir}"
done

exec /init "${@}"
