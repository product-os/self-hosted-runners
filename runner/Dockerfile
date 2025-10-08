ARG OS_CODENAME=jammy

####################################################################################################

FROM golang:1.25.2 AS eget-build

WORKDIR /src

ARG EGET_VERSION=v1.3.3
ARG CGO_ENABLED=0

RUN git clone https://github.com/zyedidia/eget . \
    && git checkout -q ${EGET_VERSION} \
    && make build \
    && make install

WORKDIR /opt

####################################################################################################

FROM eget-build AS actions-runner

# renovate: datasource=github-releases depName=actions/runner
ARG ACTIONS_RUNNER_VERSION=v2.328.0

RUN eget actions/runner \
    --asset "^noexternals" --asset "^noruntime" --asset ".tar.gz" \
    --all --file "*" --to "/opt/" \
    --tag "${ACTIONS_RUNNER_VERSION}"

####################################################################################################

FROM eget-build AS runner-container-hooks

# renovate: datasource=github-releases depName=actions/runner-container-hooks
ARG ACTIONS_HOOKS_VERSION=v0.8.0

RUN eget actions/runner-container-hooks \
    --asset "docker" --asset ".zip" \
    --all --file "*" --to "./" \
    --tag "${ACTIONS_HOOKS_VERSION}"

####################################################################################################

FROM eget-build AS powershell

# renovate: datasource=github-releases depName=powershell/powershell
ARG POWERSHELL_VERSION=v7.5.3

# https://learn.microsoft.com/en-us/powershell/scripting/install/install-other-linux#installation-using-a-binary-archive-file
RUN eget powershell/powershell \
    --asset "powershell" --asset "^fxdependent" --asset "^musl" --asset ".tar.gz" \
    --all --file "*" --to "./" \
    --tag "${POWERSHELL_VERSION}" \
    && chmod +x pwsh

####################################################################################################

FROM eget-build AS balena-cli

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v22.4.9

RUN eget balena-io/balena-cli \
    --asset "standalone" --asset ".tar.gz" \
    --all --file "*" --to "./" \
    --tag "${BALENA_CLI_VERSION}" \
    && ./balena/bin/balena version

####################################################################################################

FROM eget-build AS yq

# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.47.2

RUN eget mikefarah/yq \
    --asset ".tar.gz" \
    --file "yq_*" --to "./yq" \
    --tag "${YQ_VERSION}" \
    && ./yq --version

####################################################################################################

FROM eget-build AS gh-cli

# renovate: datasource=github-releases depName=cli/cli
ARG GH_CLI_VERSION=v2.81.0

RUN eget cli/cli \
    --asset ".tar.gz" \
    --file "gh" --to "./gh" \
    --tag "${GH_CLI_VERSION}" \
    && ./gh version

####################################################################################################

FROM eget-build AS awscli

# renovate: datasource=github-tags depName=aws/aws-cli
ARG AWSCLI_VERSION=2.31.11

# install awscli manually as it's not available in apt for Ubuntu 24.04
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
RUN eget "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-${AWSCLI_VERSION}.zip" \
    --all --file "*" --to "./" \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && aws --version

####################################################################################################

FROM eget-build AS kubectl

# renovate: datasource=github-tags depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.34.1

RUN eget "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl" \
    --all --file "*" --to "/opt" \
    --tag "${KUBECTL_VERSION}" \
    && ./kubectl version --client

####################################################################################################

FROM eget-build AS s6-overlay

# renovate: datasource=github-releases depName=just-containers/s6-overlay versioning=loose
ARG S6_OVERLAY_VERSION=v3.2.1.0

RUN eget just-containers/s6-overlay \
    --asset "s6-overlay-$(uname -m).tar.xz" \
    --all --file "*" --to "./" \
    --tag "${S6_OVERLAY_VERSION}"

# hadolint ignore=DL3059
RUN eget just-containers/s6-overlay \
    --asset "s6-overlay-noarch.tar.xz" \
    --all --file "*" --to "./" \
    --tag "${S6_OVERLAY_VERSION}"

# hadolint ignore=DL3059
RUN eget just-containers/s6-overlay \
    --asset "s6-overlay-symlinks-noarch.tar.xz" \
    --all --file "*" --to "./" \
    --tag "${S6_OVERLAY_VERSION}"

# hadolint ignore=DL3059
RUN eget just-containers/s6-overlay \
    --asset "s6-overlay-symlinks-arch.tar.xz" \
    --all --file "*" --to "./" \
    --tag "${S6_OVERLAY_VERSION}"

####################################################################################################

FROM eget-build AS go-github-apps

# renovate: datasource=github-releases depName=nabeken/go-github-apps
ARG GO_GITHUB_APPS_VERSION=v0.2.4

RUN eget nabeken/go-github-apps \
    --asset ".tar.gz" \
    --file "go-github-apps" --to "./go-github-apps" \
    --tag "${GO_GITHUB_APPS_VERSION}" \
    && ./go-github-apps -version

####################################################################################################

FROM eget-build AS node

# renovate: datasource=node depName=node
ARG NODE_VERSION=24.9.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN eget "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-$(dpkg --print-architecture | sed 's/amd/x/').tar.gz" \
    --all --file "*/*" --to "./" \
    && ./bin/node --version

####################################################################################################

# https://hub.docker.com/_/microsoft-dotnet-runtime-deps
# https://mcr.microsoft.com/en-us/product/dotnet/runtime-deps/tags

# Ubuntu 22.04 (jammy)
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0.20-jammy AS jammy
# Ubuntu 24.04 (noble)
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0.9-noble AS noble

# hadolint ignore=DL3006
FROM ${OS_CODENAME} AS runtime

WORKDIR /root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

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

# Add keyring for docker-ce
# https://docs.docker.com/engine/install/ubuntu/
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Create the docker group with our chosen GID
# otherwise the apt installation of docker-ce will create the group with a different GID
RUN groupadd docker --gid 123

# renovate: datasource=github-releases depName=docker/cli
ARG DOCKER_VERSION=v27.4.1

# renovate: datasource=github-releases depName=docker/compose
ARG DOCKER_COMPOSE_VERSION=v2.40.0

# renovate: datasource=github-releases depName=docker/buildx
ARG DOCKER_BUILDX_VERSION=v0.29.1

ARG PACKAGES_common="\
    bind9-dnsutils \
    build-essential \
    cpu-checker \
    containerd.io \
    docker-buildx-plugin=${DOCKER_BUILDX_VERSION/v/}* \
    docker-ce-cli=5:${DOCKER_VERSION/v/}* \
    docker-ce=5:${DOCKER_VERSION/v/}* \
    docker-compose-plugin=${DOCKER_COMPOSE_VERSION/v/}* \
    dosfstools \
    git \
    htop \
    imvirt \
    iproute2 \
    iptables \
    iputils-ping \
    jq \
    nfs-common \
    openssh-client \
    pigz \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    rsync \
    socat \
    unzip \
    uuid-runtime \
    vim \
    wget \
    zstd \
    "

# install dotnet dependencies for jammy (Ubuntu 22.04)
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#dependencies
ARG PACKAGES_jammy="\
    ${PACKAGES_common} \
    libc6 \
    libgcc-s1 \
    libgssapi-krb5-2 \
    libicu70 \
    liblttng-ust1 \
    libssl3 \
    libstdc++6 \
    libunwind8 \
    zlib1g \
    "

# install dotnet dependencies for noble (Ubuntu 24.04)
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#dependencies
ARG PACKAGES_noble="\
    ${PACKAGES_common} \
    libc6 \
    libgcc-s1 \
    libgssapi-krb5-2 \
    libicu74 \
    liblttng-ust1 \
    libssl3 \
    libstdc++6 \
    libunwind8 \
    zlib1g \
    "

# hadolint ignore=DL3008,SC2046
RUN apt-get update && apt-get install -y --no-install-recommends \
    $(eval echo "\$PACKAGES_$(lsb_release -cs)") \
    && rm -rf /var/lib/apt/lists/*

# Create runner user and add to groups
RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

WORKDIR /home/runner

COPY --from=actions-runner /opt/ /home/runner/
COPY --from=runner-container-hooks /opt/ /home/runner/docker/
COPY --from=powershell /opt/ /opt/microsoft/powershell/7/

RUN ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    pwsh -Version

COPY --from=yq /opt/ /usr/local/bin/
COPY --from=gh-cli /opt/ /usr/local/bin/
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=awscli /usr/local/bin/ /usr/local/bin/
COPY --from=kubectl /opt/ /usr/local/bin/
COPY --from=go-github-apps /opt/ /usr/local/bin/
COPY --from=balena-cli /opt/balena/ /usr/local/lib/balena/

RUN ln -sf /usr/local/lib/balena/bin/balena /usr/local/bin/balena && \
    balena version

COPY --from=s6-overlay /opt/ /

COPY --from=node /opt/ /usr/local/

# Fix global modules installation as regular user
# https://github.com/actions/virtual-environments/issues/3727
RUN chmod -R 777 /usr/local/lib/node_modules \
    && chmod -R 777 /usr/local/bin

# install any missing runner dotnet dependencies
# https://github.com/actions/runner/blob/main/src/Misc/layoutbin/installdependencies.sh
RUN /home/runner/bin/installdependencies.sh

# renovate: datasource=npm depName=npm
ARG NPM_VERSION=11.6.2

# install npm
RUN npm install -g "npm@${NPM_VERSION}" \
    && rm -rf /root/.npm/_cacache \
    && npm cache clear --force \
    && rm -rf /tmp/*

# install s6-overlay
COPY s6-overlay /etc/s6-overlay
RUN chmod +x /etc/s6-overlay/scripts/*

# install GH unregister script
COPY cont-finish.d /etc/cont-finish.d
RUN chmod +x /etc/cont-finish.d/*

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
ENV BALENARC_NO_SENTRY=1
ENV BALENARC_NO_ANALYTICS=1

# set balena to offline mode in this context only
ARG BALENARC_OFFLINE_MODE=1

# For reference, here are the packages in the official hosted runners:
# - https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2204-Readme.md
# - https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2004-Readme.md
RUN aws --version && \
    balena version && \
    ctr --version && \
    curl --version && \
    docker --version && \
    docker buildx version && \
    docker compose version && \
    gh version && \
    kubectl version --client && \
    node --version && \
    npm --version && \
    pwsh -Version && \
    python3 --version && \
    runc --version && \
    s6-rc help && \
    socat -V && \
    yq --version && \
    zstd --version

# switch back to root user for s6 entrypoint
# hadolint ignore=DL3002
USER root

ARG TARGETPLATFORM

ENV ACTIONS_RUNNER_BUILD_LABELS="platform:${TARGETPLATFORM} runtime:container"

# allow propegating env vars to s6-services
ENV S6_KEEP_ENV=1
ENV S6_READ_ONLY_ROOT=1
# give services 30 seconds to start
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000
# stop the container if any services fail to start
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ENV DOCKER_DATA_ROOT=/scratch/docker
ENV DOCKER_PIDFILE=/var/run/docker.pid
ENV DOCKER_DEFAULT_ULIMITS="nofile:65535,65535"

CMD [ "/init.container" ]

# This volume is used to store the rootfs for the chroot environment.
# It must be an ext4 or tmpfs volume, and not overlayfs.
VOLUME /rootfs
