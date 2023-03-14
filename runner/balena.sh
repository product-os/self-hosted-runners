#!/usr/bin/env bash

set -ae

[[ $VERBOSE =~ true|True|yes|Yes|on|On|1 ]] && set -x

if [[ $DISABLED =~ true|True|yes|Yes|on|On|1 ]]; then
    echo 'Container still running...'
    sleep infinity
fi

ACTIONS_RUNNER_NAME=${ACTIONS_RUNNER_NAME:-$(uuidgen)}
# Configure the runner to only take one job and then let the service un-configure the runner after the job finishes (default false)
ACTIONS_RUNNER_EPHEMERAL=${ACTIONS_RUNNER_EPHEMERAL:-false)}
# Replace any existing runner with the same name (default false)
ACTIONS_RUNNER_REPLACE=${ACTIONS_RUNNER_REPLACE:-false)}
ACTIONS_RUNNER_GROUP=${ACTIONS_RUNNER_GROUP:-self-hosted}
DOCKER_REGISTRY_MIRROR_INTERNAL=${DOCKER_REGISTRY_MIRROR_INTERNAL:-""}
DOCKER_REGISTRY_MIRROR=${DOCKER_REGISTRY_MIRROR:-""}
GITHUB_ORG=${GITHUB_ORG:-balena-io}
MAX_CONCURRENT_DOWNLOADS=${MAX_CONCURRENT_DOWNLOADS:-3}
MAX_CONCURRENT_UPLOADS=${MAX_CONCURRENT_UPLOADS:-5}
NODE_VERSION=${NODE_VERSION:-18}
NVM_VERSION=${NVM_VERSION:-0.39.3}

function cleanup() {
    if [[ -s "/balena/token.${ACTIONS_RUNNER_NAME}" ]]; then
        runner_token="$(cat < "/balena/token.${ACTIONS_RUNNER_NAME}")"
        ./config.sh remove --token "${runner_token}"
        sudo rm -f "/balena/token.${ACTIONS_RUNNER_NAME}"
    fi
    sudo rm -f .runner
    sleep "$(( (RANDOM % 10) + 10))s"
}

trap 'cleanup' EXIT

curl_with_opts() {
    curl --fail --silent --retry 3 --connect-timeout 3 "$@"
}

function get_geo() {
    if curl_with_opts -I https://ipinfo.io; then
        geoip_api_url=https://ipinfo.io
        if [[ -n $GEOIP_API_TOKEN ]]; then
            geoip_api_url="${geoip_api_url}?token=${GEOIP_API_TOKEN}"
        fi
        ipinfo="$(curl_with_opts "${geoip_api_url}")"
    else
        ipinfo='{"city":"Unknown","region":"Unknown","country":"Unknown"}'
    fi
}

# override /proc/cpuinfo for ARM variants
# see: https://github.com/containerd/containerd/pull/7636
function override_cpuinfo() {
    # nothing to do if the cpuinfo is already correct
    if grep -q "CPU architecture: ${1}" /proc/cpuinfo
    then
        return 0
    fi

    echo "CPU architecture: ${1}" > /tmp/cpuinfo
    sudo mount --bind /tmp/cpuinfo /proc/cpuinfo
}

function local_start_docker() {
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

    # shellcheck disable=SC2086
    if [[ -z "${DOCKER_HOST}" ]]; then
        sudo -Eb ./start-docker.sh &
    fi
}

function start_github_runner() {
    [[ -z $GH_TOKEN ]] && false

    mkdir -p "${HOME}/_work"
    sudo chown -R "$(id -un):$(id -gn)" "${HOME}"

    get_geo

    family="$(cat < /etc/lsb-release | grep DISTRIB_ID | awk -F'=' '{print $2}')"
    distro="$(cat < /etc/lsb-release | grep DISTRIB_CODENAME | awk -F'=' '{print $2}' | sed 's/"//g')"
    major="$(cat < /etc/lsb-release | grep DISTRIB_RELEASE | awk -F'=' '{print $2}' | sed 's/"//g')"
    minor="$(cat < /etc/lsb-release | grep DISTRIB_DESCRIPTION | awk -F'=' '{print $2}' | sed 's/"//g')"
    # TODO: why are machine and arch incorrect on our custom arm32 docker socket?
    machine="$(uname -m)"
    arch="$(dpkg --print-architecture)"
    board="$(cat < /sys/devices/virtual/dmi/id/board_name || echo 'unknown')"
    cpu="$(nproc)"
    mem="$(($(cat < /proc/meminfo | grep MemTotal | awk '{print $2}') / 1024 / 1024))Gi"
    country="$(echo "${ipinfo}" | jq -r .country | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
    region="$(echo "${ipinfo}" | jq -r .region | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
    city="$(echo "${ipinfo}" | jq -r .city | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
    platform="${ACTIONS_RUNNER_PLATFORM}"

    ACTIONS_RUNNER_TAGS=${ACTIONS_RUNNER_TAGS:-family:${family},distro:${distro},major:${major},minor:${minor},machine:${machine},arch:${arch},board:${board},mem:${mem},cpu:${cpu},country:${country},region:${region},city:${city},platform:${platform}}

    if [[ -n $ACTIONS_RUNNER_EXTRA_TAGS ]]; then
        ACTIONS_RUNNER_TAGS="${ACTIONS_RUNNER_TAGS},${ACTIONS_RUNNER_EXTRA_TAGS}"
    fi

    slug=orgs
    url="https://github.com/${GITHUB_ORG}"
    if [[ -n $GITHUB_ENTERPRISE ]]; then
        GITHUB_ORG="${GITHUB_ENTERPRISE}"
        slug=enterprises
        url="https://github.com/${slug}/${GITHUB_ENTERPRISE}"
    fi

    registration_url="https://api.github.com/${slug}/${GITHUB_ORG}/actions/runners/registration-token"
    payload=$(curl_with_opts -sX POST "${registration_url}" -H "Authorization: token ${GH_TOKEN}")
    runner_token="$(echo "${payload}" | jq -r .token)"
    echo "${runner_token}" | sudo tee "/balena/token.${ACTIONS_RUNNER_NAME}"

    # shellcheck disable=SC2086
    ./config.sh --unattended \
      $([[ $ACTIONS_RUNNER_EPHEMERAL =~ true|True|1|yes|Yes ]] && echo --ephemeral) \
      $([[ $ACTIONS_RUNNER_REPLACE =~ true|True|1|yes|Yes ]] && echo --replace) \
      --name "${ACTIONS_RUNNER_NAME}" \
      --token "${runner_token}" \
      --url "${url}" \
      --runnergroup "${ACTIONS_RUNNER_GROUP}" \
      --labels "${ACTIONS_RUNNER_TAGS}"

    ./run.sh "$*" &
}

local_start_docker

start_github_runner "$*"

wait $!
