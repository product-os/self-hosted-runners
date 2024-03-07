ARG OS_CODENAME=jammy

FROM golang:1.22.0 AS eget-build

WORKDIR /src

ARG EGET_VERSION=v1.3.3
ARG CGO_ENABLED=0

RUN git clone https://github.com/zyedidia/eget . \
    && git checkout -q ${EGET_VERSION} \
    && make build

# https://hub.docker.com/_/microsoft-dotnet-runtime-deps
# https://mcr.microsoft.com/en-us/product/dotnet/runtime-deps/tags
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0.2-jammy AS jammy
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.27-focal AS focal
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

# Add keyring for container tools (podman, buildah, skopeo)
# https://github.com/actions/runner-images/blob/main/images/linux/scripts/installers/containers.sh
RUN url="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x$(lsb_release -is)_$(lsb_release -rs)" \
    && sh -c "echo 'deb ${url}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list" \
    && curl -fsSL "${url}/Release.key" | apt-key add -

# Add keyring for GH CLI releases
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

COPY config/packages.* ./config/

# hadolint ignore=DL3008,SC2046
RUN apt-get update && apt-get install -y --no-install-recommends \
    $(<./config/packages.txt) \
    $(<./config/packages."$(lsb_release -cs)".txt) \
    && rm -rf /var/lib/apt/lists/*

# https://github.com/actions/runner-images/blob/main/images/linux/scripts/installers/containers.sh
RUN echo -e "[registries.search]\nregistries = ['docker.io', 'quay.io']" | tee /etc/containers/registries.conf

COPY --from=eget-build /src/eget /usr/local/bin/eget

# renovate: datasource=github-releases depName=actions/runner
ARG ACTIONS_RUNNER_VERSION=v2.314.1

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget actions/runner \
    --asset "^noexternals" --asset "^noruntime" --asset ".tar.gz" \
    --all --file "*" --to "/home/runner" \
    --tag "${ACTIONS_RUNNER_VERSION}"

# renovate: datasource=github-releases depName=actions/runner-container-hooks
ARG ACTIONS_HOOKS_VERSION=v0.5.1

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget actions/runner-container-hooks \
    --asset "docker" --asset ".zip" \
    --all --file "*" --to "/home/runner/docker" \
    --tag "${ACTIONS_HOOKS_VERSION}"

# renovate: datasource=github-releases depName=powershell/powershell
ARG POWERSHELL_VERSION=v7.4.1

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
ARG BALENA_CLI_VERSION=v18.0.1

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
ARG GH_CLI_VERSION=v2.45.0

# mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# hadolint ignore=DL3059
RUN --mount=type=secret,id=GITHUB_TOKEN \
    GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) \
    eget cli/cli \
    --asset ".tar.gz" \
    --file "gh" --to "/usr/local/bin/gh" \
    --tag "${GH_CLI_VERSION}" \
    && gh version

# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.1.4.2

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

# renovate: datasource=node depName=node
ARG NODE_VERSION=20.11.1

# renovate: datasource=npm depName=npm
ARG NPM_VERSION=10.5.0

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

# install github-app-installation-token
# https://www.npmjs.com/package/github-app-installation-token
RUN npm install -g github-app-installation-token@^1.2.0 \
    && rm -rf /root/.npm/_cacache \
    && npm cache clear --force \
    && rm -rf /tmp/*

# install s6-overlay
COPY s6-overlay /etc/s6-overlay
RUN chmod +x /etc/s6-overlay/scripts/*

# hadolint ignore=DL3059
RUN chown -R runner:runner /home/runner

# switch to runner user to check package versions
USER runner

# hadolint ignore=SC2016
RUN echo 'export PATH=/home/runner/.local/bin:$PATH' >> /home/runner/.profile

# For reference, here are the packages in the official hosted runners:
# - https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2204-Readme.md
# - https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2004-Readme.md
RUN aws --version && \
    balena version && \
    buildah --version && \
    ctr --version && \
    docker buildx version && \
    docker compose version && \
    gh version && \
    node --version && \
    npm --version && \
    podman --version && \
    pwsh -Version && \
    python3 --version && \
    runc --version && \
    skopeo --version && \
    socat -V && \
    yq --version && \
    zstd --version

# switch back to root user for s6 entrypoint
# hadolint ignore=DL3002
USER root

ARG TARGETPLATFORM

ENV ACTIONS_RUNNER_BUILD_TAGS "platform:${TARGETPLATFORM},runtime:container"
ENV RUNNER_ALLOW_RUNASROOT 0
ENV RUNNER_MANUALLY_TRAP_SIG 1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT 1
ENV S6_KEEP_ENV 1
ENV S6_READ_ONLY_ROOT 1
# default is 5000ms
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME 20000

CMD [ "/etc/s6-overlay/scripts/remount", "/init" ]

# https://github.com/balena-io-experimental/container-jail
FROM ghcr.io/balena-io-experimental/container-jail:0.0.39 AS vm

COPY --from=runtime / /usr/src/app/rootfs

ARG TARGETPLATFORM

ENV ACTIONS_RUNNER_BUILD_TAGS "platform:${TARGETPLATFORM},runtime:vm"
ENV RUNNER_ALLOW_RUNASROOT 0
ENV RUNNER_MANUALLY_TRAP_SIG 1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT 1
ENV S6_KEEP_ENV 1
ENV S6_READ_ONLY_ROOT 1
# default is 5000ms
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME 20000

CMD [ "/init" ]
