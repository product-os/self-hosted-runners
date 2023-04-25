#!/usr/bin/env bash

set -ae

[[ $VERBOSE =~ true|True|yes|Yes|on|On|1 ]] && set -x

ACTIONS_RUNNER_NAME=${ACTIONS_RUNNER_NAME:-$(uuidgen)}
# Configure the runner to only take one job and then let the service un-configure the runner after the job finishes (default false)
ACTIONS_RUNNER_EPHEMERAL=${ACTIONS_RUNNER_EPHEMERAL:-false}
# Replace any existing runner with the same name (default false)
ACTIONS_RUNNER_REPLACE=${ACTIONS_RUNNER_REPLACE:-false}
ACTIONS_RUNNER_GROUP=${ACTIONS_RUNNER_GROUP:-self-hosted}
GITHUB_ORG=${GITHUB_ORG:-balena-io}

function cleanup() {
    if [[ -s "/var/run/runner.token" ]]; then
        s6-setuidgid github /home/github/config.sh remove --token "$(</var/run/runner.token)"
    fi

    rm -f /var/run/runner.token
    rm -f /home/github/.runner
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

get_geo

family="$(cat </etc/lsb-release | grep DISTRIB_ID | awk -F'=' '{print $2}')"
distro="$(cat </etc/lsb-release | grep DISTRIB_CODENAME | awk -F'=' '{print $2}' | sed 's/"//g')"
major="$(cat </etc/lsb-release | grep DISTRIB_RELEASE | awk -F'=' '{print $2}' | sed 's/"//g')"
minor="$(cat </etc/lsb-release | grep DISTRIB_DESCRIPTION | awk -F'=' '{print $2}' | sed 's/"//g')"
machine="$(uname -m)"
arch="$(dpkg --print-architecture)"
board="$(cat </sys/devices/virtual/dmi/id/board_name || echo 'unknown')"
cpu="$(nproc)"
mem="$(($(cat </proc/meminfo | grep MemTotal | awk '{print $2}') / 1024 / 1024))Gi"
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
if [[ -n "${GITHUB_ENTERPRISE}" ]]; then
    GITHUB_ORG="${GITHUB_ENTERPRISE}"
    slug=enterprises
    url="https://github.com/${slug}/${GITHUB_ENTERPRISE}"
fi

if [[ -z "${GH_TOKEN:-${GITHUB_TOKEN}}" ]]; then
    echo "GH_TOKEN/GITHUB_TOKEN is not set"
    exit 1
fi

GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN}}"

registration_url="https://api.github.com/${slug}/${GITHUB_ORG}/actions/runners/registration-token"
payload=$(curl_with_opts -sX POST "${registration_url}" -H "Authorization: token ${GH_TOKEN}")
runner_token="$(echo "${payload}" | jq -r .token)"

# write token to file to be read during teardown
echo "${runner_token}" >"/var/run/runner.token"

config_args=()
config_args+=("--unattended")
config_args+=("--name" "${ACTIONS_RUNNER_NAME}")
config_args+=("--token" "${runner_token}")
config_args+=("--url" "${url}")
config_args+=("--runnergroup" "${ACTIONS_RUNNER_GROUP}")
config_args+=("--labels" "${ACTIONS_RUNNER_TAGS}")

[[ ${ACTIONS_RUNNER_EPHEMERAL} =~ true|True|1|yes|Yes ]] && config_args+=("--ephemeral")
[[ ${ACTIONS_RUNNER_REPLACE} =~ true|True|1|yes|Yes ]] && config_args+=("--replace")

mkdir -p "/home/github/_work"
chown -R "github:github" /home/github

rm -f /var/run/runner.token
rm -f /home/github/.runner

su - github -c "/home/github/config.sh ${config_args[*]}" 2>&1

exec su - github -c "/home/github/run.sh" 2>&1
