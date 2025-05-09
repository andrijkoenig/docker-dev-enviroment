FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV NVIM_CONFIG_REPO=https://github.com/andrijkoenig/.config.git
ENV NVIM_CONFIG_DIR=/home/devuser/.config

# Create user
RUN useradd -ms /bin/bash devuser

# Install sudo so devuser can use it if needed at runtime
RUN apt-get update && apt-get install -y sudo

# Give sudo to devuser
RUN echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install system packages
RUN apt-get update && apt-get install -y \
    curl wget git unzip software-properties-common gnupg2 lsb-release \
    build-essential gnupg \
    ninja-build gettext cmake \
    ripgrep fzf tree tmux htop python3-pip zsh && \
    rm -rf /var/lib/apt/lists/*

# Install .NET SDK 8
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y dotnet-sdk-8.0 && \
    rm packages-microsoft-prod.deb && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 18 & Angular CLI
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @angular/cli && \
    rm -rf /var/lib/apt/lists/*

# Install Java (OpenJDK 17)
RUN apt-get update && apt-get install -y openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*

# Clone and build Neovim from source
RUN git clone --branch v0.11.1 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && \
    make CMAKE_BUILD_TYPE=Release && \
    make install && \
    rm -rf /tmp/neovim

# Install Neovim config (dotfiles)
RUN git clone --depth 1 $NVIM_CONFIG_REPO $NVIM_CONFIG_DIR && \
    chown -R devuser:devuser $NVIM_CONFIG_DIR && \
    mv $NVIM_CONFIG_DIR/.zshrc /home/devuser/.zshrc && \
    chown devuser:devuser /home/devuser/.zshrc

# Install Lazy.nvim plugin manager
RUN git clone --depth=1 https://github.com/folke/lazy.nvim.git /home/devuser/.local/share/nvim/lazy/lazy.nvim && \
    chown -R devuser:devuser /home/devuser/.local

# Neovim Python support
RUN pip3 install --break-system-packages pynvim



RUN usermod -s /bin/zsh devuser

# Set working directory and switch to non-root user
WORKDIR /home/devuser
USER devuser

# Install plugins and LSP servers using headless Neovim
RUN nvim --headless "+Lazy! sync" +qa
RUN nvim --headless "+MasonUpdate" +qa
RUN nvim --headless "+MasonInstall typescript-language-server lua-language-server tinymist jdtls omnisharp" +qa


# Run zsh on container start
CMD [ "zsh" ]