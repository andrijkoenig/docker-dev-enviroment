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
    ninja-build gettext cmake clangd-12 \
    ripgrep fzf tree tmux htop python3-pip zsh && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-12 100

# Install .NET SDK 8
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y dotnet-sdk-9.0 && \
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
RUN git clone --branch v0.11.4 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && \
    make CMAKE_BUILD_TYPE=Release && \
    make install && \
    rm -rf /tmp/neovim

# Install Neovim config (dotfiles)
RUN git clone --depth 1 $NVIM_CONFIG_REPO $NVIM_CONFIG_DIR && \
    chown -R devuser:devuser $NVIM_CONFIG_DIR && \
    mv $NVIM_CONFIG_DIR/.zshrc /home/devuser/.zshrc && \
    chown devuser:devuser /home/devuser/.zshrc

# Neovim Python support
RUN pip3 install --break-system-packages pynvim

# ========================
# Install Language Servers
# ========================

# JS/TS, Angular, HTML, CSS, Emmet, Tailwind, Prettier
RUN npm install -g \
    typescript typescript-language-server \
    @angular/language-server \
    vscode-langservers-extracted \
    @tailwindcss/language-server \
    emmet-ls \
    prettier

# Lua Language Server
RUN curl -LO https://github.com/LuaLS/lua-language-server/releases/download/3.15.0/lua-language-server-3.15.0-linux-x64.tar.gz && \
    mkdir -p /opt/lua-language-server && \
    tar -xzf lua-language-server-3.15.0-linux-x64.tar.gz -C /opt/lua-language-server --strip-components=1 && \
    ln -s /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server && \
    rm lua-language-server-3.15.0-linux-x64.tar.gz

# Roylyn (C# LSP)
RUN curl -LO https://www.nuget.org/api/v2/package/Microsoft.CodeAnalysis.LanguageServer.neutral/5.0.0-1.25277.114 && \
    mkdir -p /opt/royslin && \
    unzip 5.0.0-1.25277.114 -d /tmp/lsp && \
    mv /tmp/lsp/content/LanguageServer/neutral /opt/royslin


# ========================

RUN usermod -s /bin/zsh devuser

# Set working directory and switch to non-root user
WORKDIR /home/devuser
USER devuser

# Install plugins and LSP servers using headless Neovim
RUN nvim --headless "+Lazy! sync" +qa

# Ensure the script is executable
RUN chmod +x $NVIM_CONFIG_DIR/scripts/container_startup_script.sh

# Set default command to run the tmux script
CMD ["/home/devuser/.config/scripts/container_startup_script.sh"]
