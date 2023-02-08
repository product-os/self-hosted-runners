ARG UBUNTU_LTS=7.0.2-jammy

# https://hub.docker.com/_/microsoft-dotnet-runtime-deps
FROM mcr.microsoft.com/dotnet/runtime-deps:${UBUNTU_LTS}-arm32v7 AS arm
FROM mcr.microsoft.com/dotnet/runtime-deps:${UBUNTU_LTS}-arm64v8 AS arm64
FROM mcr.microsoft.com/dotnet/runtime-deps:${UBUNTU_LTS}-amd64 AS amd64


# --- build
FROM ${TARGETARCH} as build

# https://github.com/actions/runner/pkgs/container/actions-runner
ARG RUNNER_VERSION=2.301.1

# https://github.com/actions/runner-container-hooks/releases
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.2.0

# https://github.com/mikefarah/yq/releases (update yq_hashes)
ARG YQ_VERSION=4.27.5

ARG TARGETARCH
ENV TARGETARCH ${TARGETARCH}

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt install -y \
    curl \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY yq_hashes .

RUN wget -q https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}.tar.gz -O - | tar xz \
    && sha256=$(sha256sum yq_linux_${TARGETARCH} | awk '{print $1}') \
    && grep yq_linux_${TARGETARCH} yq_hashes | grep ${sha256} yq_hashes \
    && mv yq_linux_${TARGETARCH} /usr/bin/yq

WORKDIR /actions-runner
RUN runner_arch=$(echo ${TARGETARCH} | sed 's/amd/x/g') \
    && curl -sfLo runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${runner_arch}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz

RUN curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip


# --- runtime
FROM ${TARGETARCH}

# https://docs.docker.com/engine/release-notes
ARG DOCKER_VERSION=23.0.0

ENV DEBIAN_FRONTEND noninteractive
ENV RUNNER_ALLOW_RUNASROOT=0
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

RUN apt update && apt install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    htop \
    iproute2 \
    jq \
    lsb-release \
    openssh-client \
    software-properties-common \
    sudo \
    uuid-runtime \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/bin/yq /usr/bin/yq

# https://docs.docker.com/engine/install/ubuntu/
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && usermod -aG docker github \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER github

WORKDIR /home/github

COPY --from=build /actions-runner .
COPY --chown=github:github common.sh start-docker.sh balena.sh .

RUN sudo chmod +x ./balena.sh

ENTRYPOINT ["/home/github/balena.sh"]
