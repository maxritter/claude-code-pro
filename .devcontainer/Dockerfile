FROM --platform=linux/arm64 mcr.microsoft.com/devcontainers/base:debian-12

SHELL ["/bin/bash", "-l", "-c"]

# Install standard dependencies
RUN apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git jq zsh vim netcat-openbsd \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev