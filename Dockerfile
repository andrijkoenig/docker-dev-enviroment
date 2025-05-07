FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV NVIM_CONFIG_REPO=https://github.com/andrijkoenig/dotfiles.git
ENV NVIM_CONFIG_DIR=/home/devuser/.config

# Create user
RUN useradd -ms /bin/bash devuser

# Install system packages
RUN apt-get update && apt-get install -y \
    curl wget git unzip software-properties-common gnupg2 lsb-release \
    build-essential apt-transport-https ca-certificates gnupg \
	ninja-build gettext cmake \
    ripgrep fzf tree tmux htop python3-pip \
    bash-completion sudo

# Give sudo to devuser
RUN echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Clone and build Neovim from source
RUN git clone --branch v0.11.1 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && \
    make CMAKE_BUILD_TYPE=Release && \
    sudo make install && \
    rm -rf /tmp/neovim

# Install Neovim config (dotfiles) during build
RUN git clone --depth 1 $NVIM_CONFIG_REPO $NVIM_CONFIG_DIR && \
    chown -R devuser:devuser $NVIM_CONFIG_DIR

# Install plugins using Lazy CLI (headless)
RUN nvim --headless "+Lazy! sync" +qa

# Install .NET SDK 8
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0

# Install Node.js 18 & Angular CLI
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @angular/cli

# Install Java (OpenJDK 17)
RUN apt-get install -y openjdk-17-jdk

# Neovim Python support
RUN pip3 install --break-system-packages pynvim

USER devuser