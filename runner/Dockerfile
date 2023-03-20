ARG OS_CODENAME=jammy

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
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m github && \
    addgroup --system docker && \
    usermod -aG sudo github && \
    usermod -aG docker github && \  
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/github

ARG EGET_RELEASE=1.3.3
ARG EGET_SHA256_arm=8b13bc2dbf72a6a0ea2619663e9e5e55f74787459a88a89ebdbd390135d3b836
ARG EGET_SHA256_arm64=276d58ec76178be131fb920f3a7dea2e4603a3746c77350d9d3deffa2f5143a2
ARG EGET_SHA256_amd64=373a3bf0864344bfae684b575f01e9c4759b0aa7091dd9c325a3a373cf437d38

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN asset="eget-${EGET_RELEASE}-linux_${TARGETARCH}.tar.gz" && \
    sha256="EGET_SHA256_${TARGETARCH}" && \
    curl -fsSL -O "https://github.com/zyedidia/eget/releases/download/v${EGET_RELEASE}/${asset}" && \
    echo "${!sha256} ${asset}" | sha256sum -c - && \
    tar -xzv -C /usr/local/bin -f "${asset}" --strip-components=1 --wildcards '*/eget' && \
    rm "${asset}" && \
    chmod +x /usr/local/bin/eget

COPY ${OS_CODENAME}/${TARGETARCH}/eget.toml ./eget.toml

# optionally mount a secret with the id GITHUB_TOKEN to avoid api rate limits
# eg. DOCKER_BUILDKIT=1 docker build --secret id=GITHUB_TOKEN,src=~/github_token.txt .
# eg. docker buildx bake --set *.secrets=id=GITHUB_TOKEN,src=~/github_token.txt .
RUN --mount=type=secret,id=GITHUB_TOKEN \
    test -f /run/secrets/GITHUB_TOKEN && GITHUB_TOKEN=$(</run/secrets/GITHUB_TOKEN) eget -D || eget -D \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    chown -R github:github .

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
