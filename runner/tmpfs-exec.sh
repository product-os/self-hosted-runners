#!/usr/bin/env sh

# these tmpfs mounts need the executable bit set
mount -o remount,rw,exec tmpfs /tmp
mount -o remount,rw,exec tmpfs /run

exec /init "${@}"
