# self-hosted-runners

Start a runner in a container for convenience, at the cost of security.

One of the benefits is access to features of the host kernel, including KVM.

Not recommended for public repositories!

This image is also used as the rootfs for VM-isolated runners
[here](https://github.com/product-os/github-runner-vm).

## Usage

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
      ACTIONS_RUNNER_REGISTRATION_SLUG: orgs/product-os
      # ACTIONS_RUNNER_REGISTRATION_SLUG: enterprises/balena
      # ACTIONS_RUNNER_REGISTRATION_SLUG: repos/product-os/self-hosted-runners
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
