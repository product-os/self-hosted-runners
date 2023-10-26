# self-hosted-runners

## Usage

```yaml
# docker-compose.yml
version: "2.4"

services:
  runner:
    image: ghcr.io/product-os/self-hosted-runners:latest
    privileged: true
    network_mode: host
    environment:
      GITHUB_ORG: product-os
      ACTIONS_RUNNER_EPHEMERAL: "true"
      ACTIONS_RUNNER_GROUP: Default
    tmpfs:
      - /tmp
      - /run
      - /srv
      - /scratch
```
