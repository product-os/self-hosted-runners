# self-hosted-runners

## Usage

```yaml
# docker-compose.yml
version: "2.4"

services:
  sut:
    image: ghcr.io/product-os/self-hosted-runners
    privileged: true
    restart: always
    healthcheck:
      test: |
        /bin/bash -c '\
          curl --silent --fail --unix-socket /var/run/docker.sock http:/v1.41/_ping && \
          pgrep Runner.Listener'
      interval: 300s
      timeout: 60s
      retries: 5
      start_period: 30s
    environment:
      GITHUB_ORG: product-os
      ACTIONS_RUNNER_EPHEMERAL: "true"
      ACTIONS_RUNNER_GROUP: Default
    tmpfs:
      - /tmp
      - /scratch
    volumes:
      - workspace:/home/github/_work

volumes:
  # runner workspaces should be tmpfs, but also need execute permissions
  workspace:
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: "mode=1770"
```
