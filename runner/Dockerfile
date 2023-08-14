ARG OS_CODENAME=jammy

FROM golang:1.21.0 AS eget-build

WORKDIR /src

ARG EGET_VERSION=1.3.3
ARG CGO_ENABLED=0

ADD https://github.com/zyedidia/eget/archive/refs/tags/v${EGET_VERSION}.tar.gz ./

RUN tar xvf v${EGET_VERSION}.tar.gz --strip-components=1 && make build

# https://hub.docker.com/_/microsoft-dotnet-runtime-deps
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-arm32v7 AS arm-base
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-arm64v8 AS arm64-base
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-amd64 AS amd64-base

# --- runtime
# hadolint ignore=DL3006
FROM ${TARGETARCH}-base AS runtime

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

# https://docs.docker.com/engine/install/ubuntu/
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

ARG OS_CODENAME TARGETARCH

COPY packages.txt ./common.txt
COPY ${OS_CODENAME}/packages.txt ./os.txt

# hadolint ignore=DL3008,SC2046
RUN apt-get update && apt-get install -y --no-install-recommends \
    $(<./common.txt) \
    $(<./os.txt) \
    && rm -rf /var/lib/apt/lists/* \
    && rm os.txt common.txt

COPY --from=eget-build /src/eget /usr/bin/eget

COPY ${OS_CODENAME}/${TARGETARCH}/eget.toml ./eget.toml

# renovate: datasource=github-releases depName=actions/runner
ARG ACTIONS_RUNNER_VERSION=v2.308.0

# renovate: datasource=github-releases depName=actions/runner-container-hooks
ARG ACTIONS_HOOKS_VERSION=v0.3.2

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v16.7.6

# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=v3.1.4.2

# renovate: datasource=node-version depName=node versioning=node
ARG NODEJS_VERSION=v18.14.2

# renovate: datasource=github-releases depName=powershell/powershell
ARG POWERSHELL_VERSION=v7.3.6

# substitute the variables in the eget.toml file
RUN envsubst < eget.toml > eget.toml.tmp && mv eget.toml.tmp eget.toml

# optionally mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# eg. DOCKER_BUILDKIT=1 docker build --secret id=GITHUB_TOKEN,src=~/github_token.txt .
# eg. docker buildx bake --set *.secrets=id=GITHUB_TOKEN,src=~/github_token.txt .
RUN --mount=type=secret,id=GITHUB_TOKEN \
    test -f /run/secrets/GITHUB_TOKEN && GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) eget -D || eget -D \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# (not supported) https://github.com/vercel/pkg/blob/main/README.md?plain=1#L91-L93
RUN if [ "$(uname -m)" != armv7l ]; then ln -s /usr/local/lib/balena-cli/balena /usr/local/bin/balena && balena version; fi

RUN chown -R runner:runner /home/runner

# containerd version check will fail on emulated ARM until this fix is released
# https://github.com/containerd/containerd/pull/7636
RUN pwsh -Version && \
    (containerd --version || true) && \
    (dockerd --version || true) && \
    aws --version && \
    ctr --version && \
    docker buildx version && \
    docker compose version && \
    gh version && \
    node --version && \
    npm --version && \
    runc --version && \
    socat -V && \
    yq --version && \
    zstd --version

ARG TARGETPLATFORM
ENV ACTIONS_RUNNER_PLATFORM $TARGETPLATFORM

ENV EXTRA_DOCKERD_ARGS ""
ENV RUNNER_ALLOW_RUNASROOT 0
ENV RUNNER_MANUALLY_TRAP_SIG 1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT 1
ENV S6_KEEP_ENV 1
ENV S6_READ_ONLY_ROOT 1

COPY s6-overlay /etc/s6-overlay
RUN chmod +x /etc/s6-overlay/scripts/* \
    && ln -s /etc/s6-overlay/scripts/start-runner /start-runner.sh

ENTRYPOINT [ "/etc/s6-overlay/scripts/set-arch", "/init" ]
CMD [ "/etc/s6-overlay/scripts/start-runner" ]
