#!/usr/bin/env bash

set -ae

[[ $VERBOSE =~ true|True|yes|Yes|on|On|1 ]] && set -x

function cleanup() {
    sudo rm -rf /var/run/docker.pid
}

trap 'cleanup' EXIT

source common.sh

start_docker \
  "${MAX_CONCURRENT_DOWNLOADS}" \
  "${MAX_CONCURRENT_UPLOADS}" \
  "${DOCKER_REGISTRY_MIRROR_INTERNAL}" \
  "${DOCKER_REGISTRY_MIRROR}"

chown github:github /var/run/docker.sock

while ! docker system info; do
    [ -f /tmp/docker.log ] && tail -n 10 /tmp/docker.log
    sleep "$(( ( RANDOM % 3 ) + 3 ))s"
done

tail -f /tmp/docker.log
