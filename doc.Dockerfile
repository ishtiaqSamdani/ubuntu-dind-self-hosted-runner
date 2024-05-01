# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Install necessary packages
RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        wget \
        curl \
        iptables \
        supervisor \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --set iptables /usr/sbin/iptables-legacy

# Set environment variables
ENV DOCKER_CHANNEL=stable \
    DOCKER_VERSION=26.0.1 \
    DOCKER_COMPOSE_VERSION=v2.26.1 \
    BUILDX_VERSION=v0.13.1 \
    DEBUG=false

# Docker and buildx installation
RUN set -eux; \
    \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) dockerArch='x86_64' ; buildx_arch='linux-amd64' ;; \
        armhf) dockerArch='armel' ; buildx_arch='linux-arm-v6' ;; \
        armv7) dockerArch='armhf' ; buildx_arch='linux-arm-v7' ;; \
        aarch64) dockerArch='aarch64' ; buildx_arch='linux-arm64' ;; \
        *) echo >&2 "error: unsupported architecture ($arch)"; exit 1 ;; \
    esac; \
    \
    if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
        echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
        exit 1; \
    fi; \
    \
    tar --extract \
        --file docker.tgz \
        --strip-components 1 \
        --directory /usr/local/bin/ \
    ; \
    rm docker.tgz; \
    if ! wget -O docker-buildx "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.${buildx_arch}"; then \
        echo >&2 "error: failed to download 'buildx-${BUILDX_VERSION}.${buildx_arch}'"; \
        exit 1; \
    fi; \
    mkdir -p /usr/local/lib/docker/cli-plugins; \
    chmod +x docker-buildx; \
    mv docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx; \
    \
    dockerd --version; \
    docker --version; \
    docker buildx version

# Copy necessary scripts and configurations
COPY modprobe start-docker.sh entrypoint.sh /usr/local/bin/
COPY supervisor/ /etc/supervisor/conf.d/
COPY logger.sh /opt/bash-utils/logger.sh

# Set permissions for scripts
RUN chmod +x /usr/local/bin/start-docker.sh \
    /usr/local/bin/entrypoint.sh \
    /usr/local/bin/modprobe

# Create a volume for Docker
VOLUME /var/lib/docker

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && docker-compose version

# Create a symlink to docker-compose
RUN ln -s /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose

# Set up GitHub Actions runner
WORKDIR /actions-runner
RUN curl -o actions-runner-linux-x64-2.316.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.316.0/actions-runner-linux-x64-2.316.0.tar.gz \
    && echo "64a47e18119f0c5d70e21b6050472c2af3f582633c9678d40cb5bcb852bcc18f  actions-runner-linux-x64-2.316.0.tar.gz" | sha256sum -c \
    && tar xzf actions-runner-linux-x64-2.316.0.tar.gz \
    && rm actions-runner-linux-x64-2.316.0.tar.gz \
    && ./config.sh --url https://github.com/QuikkyOrg --token ATSBQULFX5UFWFCZLZZG5YDGGDMDY

# Set entrypoint and command
ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]
