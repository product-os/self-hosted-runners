ARG OS_CODENAME=jammy

FROM golang:1.20.2 AS eget

WORKDIR /app

# build eget from source until this commit is tagged in a release
RUN git clone -n https://github.com/zyedidia/eget . && \
    git checkout ff0fd7efd18ebf8219b89ad28959ea49e8726d07 && \
    make build

# RUN curl -o eget.sh https://zyedidia.github.io/eget.sh && \
#     echo "0e64b8a3c13f531da005096cc364ac77835bda54276fedef6c62f3dbdc1ee919  eget.sh" | sha256sum - && \
#     bash eget.sh && \
#     rm eget.sh

# https://hub.docker.com/_/microsoft-dotnet-runtime-deps
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-arm32v7 AS arm
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-arm64v8 AS arm64
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.14-${OS_CODENAME}-amd64 AS amd64

# --- runtime
# hadolint ignore=DL3006
FROM ${TARGETARCH}

# dockerd startup timeout
ENV STARTUP_TIMEOUT 120
ENV EXTRA_DOCKER_OPTS "--iptables=false"

ENV DEBIAN_FRONTEND noninteractive
ENV RUNNER_ALLOW_RUNASROOT 0
ENV RUNNER_MANUALLY_TRAP_SIG 1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT 1

WORKDIR /root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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

ARG OS_CODENAME TARGETARCH

COPY packages.txt ./common.txt
COPY ${OS_CODENAME}/packages.txt ./os.txt

# hadolint ignore=DL3008,SC2046
RUN apt-get update && apt-get install -y --no-install-recommends \
    $(<./common.txt) \
    $(<./os.txt) \
    && rm -rf /var/lib/apt/lists/* \
    && rm common.txt os.txt

RUN useradd -m github && \
    addgroup --system docker && \
    usermod -aG sudo github && \
    usermod -aG docker github && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/github

COPY --from=eget /app/eget /usr/local/bin/eget

COPY ${OS_CODENAME}/${TARGETARCH}/eget.toml ./eget.toml

# optionally mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# eg. DOCKER_BUILDKIT=1 docker build --secret id=GITHUB_TOKEN,src=~/github_token.txt .
# eg. docker buildx bake --set *.secrets=id=GITHUB_TOKEN,src=~/github_token.txt .
RUN --mount=type=secret,id=GITHUB_TOKEN \
    test -f /run/secrets/GITHUB_TOKEN && GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) eget -D || eget -D \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    rm eget.toml

COPY --chown=github:github common.sh start-docker.sh balena.sh ./

RUN chmod +x ./balena.sh

USER github

# containerd version check will fail on emulated ARM until this fix is released
# https://github.com/containerd/containerd/pull/7636
RUN pwsh -Version && \
    yq --version && \
    dockerd --version ; \
    containerd --version ; \
    ctr --version && \
    runc --version && \
    docker buildx version && \
    docker compose version && \
    node --version && \
    npm --version

ARG TARGETPLATFORM
ENV ACTIONS_RUNNER_PLATFORM $TARGETPLATFORM

ENTRYPOINT ["/home/github/balena.sh"]
