ARG OS_CODENAME=jammy

FROM golang:1.20.4 AS eget-build

WORKDIR /src

ARG EGET_VERSION=1.3.3
ARG CGO_ENABLED=0

ADD https://github.com/zyedidia/eget/archive/refs/tags/v${EGET_VERSION}.tar.gz ./

RUN tar xvf v${EGET_VERSION}.tar.gz --strip-components=1 && make build

# https://hub.docker.com/_/microsoft-dotnet-runtime-deps
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-arm32v7 AS arm
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-arm64v8 AS arm64
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-amd64 AS amd64

# --- runtime
# hadolint ignore=DL3006
FROM ${TARGETARCH}

WORKDIR /root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive

# hadolint ignore=DL3008,SC2046
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

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
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m github && \
    addgroup --system docker && \
    usermod -aG sudo github && \
    usermod -aG docker github && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/github

COPY --from=eget-build /src/eget /usr/bin/eget

COPY ${OS_CODENAME}/${TARGETARCH}/eget.toml ./eget.toml

# optionally mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# eg. DOCKER_BUILDKIT=1 docker build --secret id=GITHUB_TOKEN,src=~/github_token.txt .
# eg. docker buildx bake --set *.secrets=id=GITHUB_TOKEN,src=~/github_token.txt .
RUN --mount=type=secret,id=GITHUB_TOKEN \
    test -f /run/secrets/GITHUB_TOKEN && GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) eget -D || eget -D \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

RUN chown -R github:github /home/github

# no GitHub linux/arm release(s)
RUN if [ "$(uname -m)" == x86_64 ]; then ln -s /usr/local/lib/balena-cli/balena /usr/local/bin/balena && balena version; fi

# containerd version check will fail on emulated ARM until this fix is released
# https://github.com/containerd/containerd/pull/7636
RUN pwsh -Version && \
    yq --version && \
    (dockerd --version || true) && \
    (containerd --version || true) && \
    ctr --version && \
    runc --version && \
    docker buildx version && \
    docker compose version && \
    node --version && \
    npm --version && \
    gh version && \
    zstd --version && \
    aws --version

ARG TARGETPLATFORM
ENV ACTIONS_RUNNER_PLATFORM $TARGETPLATFORM

ENV EXTRA_DOCKERD_ARGS ""
ENV RUNNER_ALLOW_RUNASROOT 0
ENV RUNNER_MANUALLY_TRAP_SIG 1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT 1
ENV S6_KEEP_ENV 1

COPY s6-overlay /etc/s6-overlay
COPY start-runner.sh /

RUN chmod +x /start-runner.sh

ENTRYPOINT [ "/init"]
CMD [ "/start-runner.sh" ]
