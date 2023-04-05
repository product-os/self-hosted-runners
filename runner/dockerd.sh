#!/usr/bin/env bash

set -ae

[[ $VERBOSE =~ true|True|yes|Yes|on|On|1 ]] && set -x

DOCKER_REGISTRY_MIRROR_INTERNAL=${DOCKER_REGISTRY_MIRROR_INTERNAL:-""}
DOCKER_REGISTRY_MIRROR=${DOCKER_REGISTRY_MIRROR:-""}
MAX_CONCURRENT_DOWNLOADS=${MAX_CONCURRENT_DOWNLOADS:-3}
MAX_CONCURRENT_UPLOADS=${MAX_CONCURRENT_UPLOADS:-5}

function cleanup() {
  sudo rm -rf /var/run/docker.pid 
}

trap 'cleanup' EXIT

# override /proc/cpuinfo for ARM variants
# see: https://github.com/containerd/containerd/pull/7636
function override_cpuinfo() {
  # nothing to do if the cpuinfo is already correct
  if grep -q "CPU architecture: ${1}" /proc/cpuinfo; then
    return 0
  fi

  echo "CPU architecture: ${1}" >/tmp/cpuinfo
  sudo mount --bind /tmp/cpuinfo /proc/cpuinfo
}

function start_docker() {
  sudo mkdir -p /var/log
  sudo mkdir -p /var/run

  sudo sysctl -w user.max_user_namespaces=15000 || true

  sudo rm -f /var/run/docker.pid

  case "$(uname -m)" in
  aarch64)
    override_cpuinfo 8
    ;;
  armv7l)
    override_cpuinfo 7
    ;;
  esac

  local mtu="$(cat /sys/class/net/"$(ip route get 8.8.8.8 | awk '{ print $5 }')"/mtu)"
  local server_args="${EXTRA_DOCKER_OPTS} --mtu ${mtu}"
  local registry=""

  server_args="${server_args} --max-concurrent-downloads=$1 --max-concurrent-uploads=$2"

  for registry in $3; do
    server_args="${server_args} --insecure-registry ${registry}"
  done

  if [ -n "$4" ]; then
    server_args="${server_args} --registry-mirror $4"
  fi

  sudo dockerd --data-root /scratch/docker ${server_args} 2>&1 &
}

start_docker \
  "${MAX_CONCURRENT_DOWNLOADS}" \
  "${MAX_CONCURRENT_UPLOADS}" \
  "${DOCKER_REGISTRY_MIRROR_INTERNAL}" \
  "${DOCKER_REGISTRY_MIRROR}"

wait $!
