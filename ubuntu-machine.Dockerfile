FROM ubuntu:latest

ENV container=container
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y \
    dbus systemd openssh-server net-tools iproute2 iputils-ping \
    curl wget vim-tiny man sudo nano bash uidmap jq \
    apt-transport-https ca-certificates curl gnupg lsb-release

RUN >/etc/machine-id
RUN >/var/lib/dbus/machine-id

RUN systemctl set-default multi-user.target
RUN systemctl mask \
      dev-hugepages.mount \
      sys-fs-fuse-connections.mount \
      systemd-update-utmp.service \
      systemd-tmpfiles-setup.service \
      console-getty.service

RUN sed -i -e 's/^AcceptEnv LANG LC_\*$/#AcceptEnv LANG LC_*/' /etc/ssh/sshd_config

# Install Docker
RUN curl -fsSL https://get.docker.com | sh
# Install Azure CLI
RUN curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | bash

# Install GitHub Actions Runner
ARG runner_version=2.335.1
RUN case "${TARGETARCH}" in \
        amd64) runner_arch=x64 ;; \
        arm64) runner_arch=arm64 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -o actions-runner-linux-${runner_arch}-${runner_version}.tar.gz -L https://github.com/actions/runner/releases/download/v${runner_version}/actions-runner-linux-${runner_arch}-${runner_version}.tar.gz && \
    mkdir -p /opt/actions-runner && \
    tar xzf actions-runner-linux-${runner_arch}-${runner_version}.tar.gz -C /opt/actions-runner && \
    rm actions-runner-linux-${runner_arch}-${runner_version}.tar.gz && \
    /opt/actions-runner/bin/installdependencies.sh

# Crate a non-root user and add to sudo group
RUN groupadd -g 1001 runner && \
    useradd -m -u 1001 -g runner -s /bin/bash runner && \
    usermod -aG sudo runner && \
    usermod -aG docker runner && \
    mkdir -p /etc/sudoers.d && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/runner && \
    chmod 440 /etc/sudoers.d/runner && \
    chown -R runner:runner /opt/actions-runner


# Cleanup after installations
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG TZ="Europe/Oslo"
ENV TZ=${TZ}
ENV RUNNER_VERSION=${runner_version}
