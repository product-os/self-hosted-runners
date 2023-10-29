# self-hosted-runners

## Usage

### VM isolated runners

Start a runner in an isolated VM for security with TUN/TAP networking.

If access to host KVM is required, use the containerized runners below, as nested KVM is not supported.

See <https://github.com/balena-io-experimental/container-jail>

```yaml
# docker-compose.yml
version: "2.4"

services:
  vm-runner:
    image: ghcr.io/product-os/self-hosted-runners:jammy-vm
    # privileged is required to mount filesystems and access KVM
    privileged: true
    # host networking is required to modify host iptables
    network_mode: host
    environment:
      GITHUB_ORG: product-os
      ACTIONS_RUNNER_GROUP: self-hosted-internal
      # optionally authenticate via GitHub App installation token (organization only, not enterprise)
      ACTIONS_RUNNER_APP_ID: "********" # GitHub App ID with permissions to manage self hosted runners
      ACTIONS_RUNNER_APP_KEY_B64: "********" # GitHub App Key with permissions to manage self hosted runners
      ACTIONS_RUNNER_INSTALLATION_ID: "********" #  # GitHub App Key with permissions to manage self hosted runners
      # OR authenticate via GitHub PAT
      ACTIONS_RUNNER_AUTH_TOKEN: "********" # GitHub PAT with permissions to manage self hosted runners
      GEOIP_API_TOKEN: "********" # optional https://ipinfo.io/login
    tmpfs:
      - /tmp
      - /run
      - /srv
```

### Containerized runners

Start a runner in a container for convenience, at the cost of security.

One of the benefits is access to features of the host kernel, including KVM.

Not recommended for public repositories!

```yaml
# docker-compose.yml
version: "2.4"

services:
  runner:
    image: ghcr.io/product-os/self-hosted-runners:latest
    # privileged is required for docker-in-docker
    privileged: true
    # hostname will be used as the runner machine name
    hostname: my-runner
    environment:
      GITHUB_ORG: product-os
      ACTIONS_RUNNER_GROUP: self-hosted-internal
      # optionally authenticate via GitHub App installation token (organization only, not enterprise)
      ACTIONS_RUNNER_APP_ID: "********" # GitHub App ID with permissions to manage self hosted runners
      ACTIONS_RUNNER_APP_KEY_B64: "********" # GitHub App Key with permissions to manage self hosted runners
      ACTIONS_RUNNER_INSTALLATION_ID: "********" #  # GitHub App Key with permissions to manage self hosted runners
      # OR authenticate via GitHub PAT
      ACTIONS_RUNNER_AUTH_TOKEN: "********" # GitHub PAT with permissions to manage self hosted runners
      GEOIP_API_TOKEN: "********" # optional https://ipinfo.io/login
    tmpfs:
      - /tmp
      - /run
      # make the docker data root a tmpfs
      - /scratch
```
