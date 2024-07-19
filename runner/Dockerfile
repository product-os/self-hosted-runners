ARG OS_CODENAME=jammy

FROM golang:1.22.5 AS remco-build

WORKDIR /src

# renovate: datasource=github-releases depName=HeavyHorst/remco
ARG REMOCO_VERSION=v0.12.4
ARG CGO_ENABLED=0

RUN git clone https://github.com/HeavyHorst/remco.git . \
    && git checkout -q ${REMOCO_VERSION} \
    && make build

RUN bin/remco -version

FROM golang:1.22.5 AS eget-build

WORKDIR /src

ARG EGET_VERSION=v1.3.3
ARG CGO_ENABLED=0

RUN git clone https://github.com/zyedidia/eget . \
    && git checkout -q ${EGET_VERSION} \
    && make build

# https://hub.docker.com/_/microsoft-dotnet-runtime-deps
# https://mcr.microsoft.com/en-us/product/dotnet/runtime-deps/tags
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0.7-jammy AS jammy
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.32-focal AS focal
# hadolint ignore=DL3006
FROM ${OS_CODENAME} AS runtime

WORKDIR /root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive

# hadolint ignore=DL3008,SC2046
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gettext-base \
    gnupg \
    lsb-release \
    software-properties-common \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && groupadd docker --gid 123 \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

WORKDIR /home/runner

# Add keyring for docker-ce
# https://docs.docker.com/engine/install/ubuntu/
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Add keyring for GH CLI releases
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

COPY root/*.txt /

# hadolint ignore=DL3008,SC2046
RUN apt-get update && apt-get install -y --no-install-recommends \
    $(</packages.txt) \
    $(</packages."$(lsb_release -cs)".txt) \
    && rm -rf /var/lib/apt/lists/*

COPY --from=eget-build /src/eget /usr/local/bin/
COPY --from=remco-build /src/bin/remco /usr/local/bin/

# renovate: datasource=github-releases depName=actions/runner
ARG ACTIONS_RUNNER_VERSION=v2.317.0

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget actions/runner \
    --asset "^noexternals" --asset "^noruntime" --asset ".tar.gz" \
    --all --file "*" --to "/home/runner" \
    --tag "${ACTIONS_RUNNER_VERSION}"

# renovate: datasource=github-releases depName=actions/runner-container-hooks
ARG ACTIONS_HOOKS_VERSION=v0.6.1

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget actions/runner-container-hooks \
    --asset "docker" --asset ".zip" \
    --all --file "*" --to "/home/runner/docker" \
    --tag "${ACTIONS_HOOKS_VERSION}"

# renovate: datasource=github-releases depName=powershell/powershell
ARG POWERSHELL_VERSION=v7.4.3

# https://learn.microsoft.com/en-us/powershell/scripting/install/install-other-linux#installation-using-a-binary-archive-file
# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget powershell/powershell \
    --asset "powershell" --asset "^fxdependent" --asset "^musl" --asset ".tar.gz" \
    --all --file "*" --to "/opt/microsoft/powershell/7" \
    --tag "${POWERSHELL_VERSION}" \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh \
    && pwsh -Version

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v18.2.33

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget balena-io/balena-cli \
    --asset "standalone" --asset ".zip"\
    --all --file "*" --to "/usr/local/lib/balena-cli" \
    --tag "${BALENA_CLI_VERSION}" \
    && ln -sf /usr/local/lib/balena-cli/balena /usr/local/bin/balena \
    && balena version

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget mikefarah/yq \
    --asset ".tar.gz" \
    --file "yq_*" --to "/usr/local/bin/yq" \
    --tag v4.40.5 \
    && yq --version

# renovate: datasource=github-releases depName=cli/cli
ARG GH_CLI_VERSION=v2.53.0

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget cli/cli \
    --asset ".tar.gz" \
    --file "gh" --to "/usr/local/bin/gh" \
    --tag "${GH_CLI_VERSION}" \
    && gh version

# renovate: datasource=github-releases depName=just-containers/s6-overlay versioning=loose
ARG S6_OVERLAY_VERSION=v3.2.0.0

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget just-containers/s6-overlay \
    --asset "s6-overlay-$(uname -m).tar.xz" \
    --all --file "*" --to "/" \
    --tag "${S6_OVERLAY_VERSION}"

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget just-containers/s6-overlay \
    --asset "s6-overlay-noarch.tar.xz" \
    --all --file "*" --to "/" \
    --tag "${S6_OVERLAY_VERSION}"

# renovate: datasource=github-releases depName=nabeken/go-github-apps
ARG GO_GITHUB_APPS_VERSION=v0.1.16

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget nabeken/go-github-apps \
    --asset ".tar.gz" \
    --file "go-github-apps" --to "/usr/local/bin/go-github-apps" \
    --tag "${GO_GITHUB_APPS_VERSION}" \
    && go-github-apps -version

# renovate: datasource=node depName=node
ARG NODE_VERSION=20.15.1

# renovate: datasource=npm depName=npm
ARG NPM_VERSION=10.8.2

# install nodejs and npm
RUN if [ "$(dpkg --print-architecture)" = "amd64" ] ; \
    then \
    NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" ; \
    else \
    NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-arm64.tar.gz" ; \
    fi && \
    curl -fsSL "${NODE_URL}" | tar xz -C /usr/local --strip-components=1 --no-same-owner \
    && npm install -g npm@"$NPM_VERSION" \
    && rm -rf /root/.npm/_cacache \
    && npm cache clear --force \
    && rm -rf /tmp/*

# install s6-overlay
COPY s6-overlay /etc/s6-overlay
RUN chmod +x /etc/s6-overlay/scripts/*

# install remco templates
COPY remco/ /etc/remco/

# install container init script
COPY init.container /init.container
RUN chmod +x /init.container

# hadolint ignore=DL3059
RUN chown -R runner:runner /home/runner

# switch to runner user to check package versions
USER runner

# hadolint ignore=SC2016
RUN echo 'export PATH=/home/runner/.local/bin:$PATH' >> /home/runner/.profile

# disable balena analytics and sentry
ENV BALENARC_NO_SENTRY 1
ENV BALENARC_NO_ANALYTICS 1

# set balena to offline mode in this context only
ARG BALENARC_OFFLINE_MODE 1

# For reference, here are the packages in the official hosted runners:
# - https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2204-Readme.md
# - https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2004-Readme.md
RUN aws --version && \
    balena version && \
    ctr --version && \
    docker buildx version && \
    docker compose version && \
    gh version && \
    node --version && \
    npm --version && \
    pwsh -Version && \
    python3 --version && \
    runc --version && \
    socat -V && \
    yq --version && \
    zstd --version

# switch back to root user for s6 entrypoint
# hadolint ignore=DL3002
USER root

ARG TARGETPLATFORM

ENV ACTIONS_RUNNER_BUILD_LABELS "platform:${TARGETPLATFORM} runtime:container"

# allow propegating env vars to s6-services
ENV S6_KEEP_ENV 1
ENV S6_READ_ONLY_ROOT 1
# give services 30 seconds to start
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME 30000
# stop the container if any services fail to start
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS: 2

ENV DOCKER_DATA_ROOT /scratch/docker
ENV DOCKER_PIDFILE /var/run/docker.pid
ENV DOCKER_DEFAULT_ULIMITS_NOFILE_HARD 65535
ENV DOCKER_DEFAULT_ULIMITS_NOFILE_SOFT 65535

# Test remco templating
RUN remco --config /etc/remco/config.toml \
    && jq . /etc/docker/daemon.json

CMD [ "/init.container" ]
