#!/usr/bin/env bash

set -ae

[[ $VERBOSE =~ true|True|yes|Yes|on|On|1 ]] && set -x

if [[ $DISABLED =~ true|True|yes|Yes|on|On|1 ]]; then
    echo 'Container still running...'
    sleep infinity
fi

ACTIONS_RUNNER_NAME=${ACTIONS_RUNNER_NAME:-$(uuidgen)}
DOCKER_REGISTRY_MIRROR_INTERNAL=${DOCKER_REGISTRY_MIRROR_INTERNAL:-""}
DOCKER_REGISTRY_MIRROR=${DOCKER_REGISTRY_MIRROR:-""}
GITHUB_ORG=${GITHUB_ORG:-balena-io}
MAX_CONCURRENT_DOWNLOADS=${MAX_CONCURRENT_DOWNLOADS:-3}
MAX_CONCURRENT_UPLOADS=${MAX_CONCURRENT_UPLOADS:-5}
NODE_VERSION=${NODE_VERSION:-18}
NVM_VERSION=${NVM_VERSION:-0.39.3}

function cleanup() {
    if [[ -s /balena/runner_token ]]; then
        runner_token="$(cat < "/balena/token.${ACTIONS_RUNNER_NAME}")"
        ./config.sh remove --token "${runner_token}"
    fi
    rm -f .runner
    sleep "$(( (RANDOM % 10) + 10))s"
}

trap 'cleanup' EXIT

curl_with_opts() {
    curl --fail --silent --retry 3 --connect-timeout 3 "$@"
}

function get_node() {
    wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
    NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install "${NODE_VERSION}"
    nvm use "${NODE_VERSION}"
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

function local_start_docker() {
    sudo sysctl -w user.max_user_namespaces=15000 || true

    sudo rm -f /var/run/docker.pid

    # shellcheck disable=SC2086
    if [[ -z "${DOCKER_HOST}" ]]; then
        sudo -Eb ./start-docker.sh &
    fi
}

function start_github_runner() {
    [[ -z $GH_TOKEN ]] && false

    mkdir -p /home/github/_work && sudo chown -R github:github /home/github/_work

    get_geo

    family="$(cat < /etc/lsb-release | grep DISTRIB_ID | awk -F'=' '{print $2}')"
    distro="$(cat < /etc/lsb-release | grep DISTRIB_CODENAME | awk -F'=' '{print $2}' | sed 's/"//g')"
    major="$(cat < /etc/lsb-release | grep DISTRIB_RELEASE | awk -F'=' '{print $2}' | sed 's/"//g')"
    minor="$(cat < /etc/lsb-release | grep DISTRIB_DESCRIPTION | awk -F'=' '{print $2}' | sed 's/"//g')"
    machine="$(dpkg --print-architecture)"
    arch="$(uname -m)"
    board="$(cat < /sys/devices/virtual/dmi/id/board_name || echo 'unknown')"
    cpu="$(nproc)"
    mem="$(($(cat < /proc/meminfo | grep MemTotal | awk '{print $2}') / 1024 / 1024))Gi"
    country="$(echo "${ipinfo}" | jq -r .country | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
    region="$(echo "${ipinfo}" | jq -r .region | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
    city="$(echo "${ipinfo}" | jq -r .city | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"

    ACTIONS_RUNNER_TAGS=${ACTIONS_RUNNER_TAGS:-family:${family},distro:${distro},major:${major},minor:${minor},machine:${machine},arch:${arch},board:${board},mem:${mem},cpu:${cpu},country:${country},region:${region},city:${city}}

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
    ./config.sh --ephemeral --replace --unattended \
      --name "${ACTIONS_RUNNER_NAME}" \
      --token "${runner_token}" \
      --url "${url}" \
      --labels "${ACTIONS_RUNNER_TAGS}"

    ./run.sh "$*" &
}

local_start_docker

get_node

start_github_runner "$*"

wait $!
