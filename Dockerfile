# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ENV LANG=C.UTF-8
ENV DOTFILES_REPO=https://github.com/andikon/dotfiles.git
ENV DOTFILES_DIR=/opt/dotfiles
ENV XDG_CONFIG_HOME=/root/.config

# Core dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git unzip ca-certificates gnupg lsb-release \
    build-essential ninja-build gettext cmake clangd \
    ripgrep fzf tree tmux htop python3-pip zsh xclip xsel \
    zoxide eza fd-find bat most command-not-found \
    && rm -rf /var/lib/apt/lists/*

# Starship prompt
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Node + Angular
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && npm install -g @angular/cli && \
    rm -rf /var/lib/apt/lists/*

# Build & install Neovim
RUN git clone --branch v0.11.5 --depth 1 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && make CMAKE_BUILD_TYPE=Release && make install && \
    rm -rf /tmp/neovim

# Dotfiles
RUN git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"

# Install dotfiles configs
RUN mkdir -p "$XDG_CONFIG_HOME" && \
    cp -rf "$DOTFILES_DIR/.config/nvim" "$XDG_CONFIG_HOME/nvim" 2>/dev/null || true && \
    cp -f "$DOTFILES_DIR/.zshrc" /root/.zshrc 2>/dev/null || true && \
    cp -f "$DOTFILES_DIR/.zprofile" /root/.zprofile 2>/dev/null || true && \
    cp -f "$DOTFILES_DIR/.config/starship.toml" "$XDG_CONFIG_HOME/starship.toml" 2>/dev/null || true && \
    cp -f "$DOTFILES_DIR/.tmux.conf" /root/.tmux.conf 2>/dev/null || true

# Move dotfiles scripts to /usr/local/bin and make executable
RUN if [ -d "$DOTFILES_DIR/scripts" ]; then \
        cp "$DOTFILES_DIR/scripts/"* /usr/local/bin/ && \
        chmod +x /usr/local/bin/* ; \
    fi

# Node-based language servers
RUN npm install -g \
    typescript typescript-language-server \
    @angular/language-server \
    vscode-langservers-extracted \
    @tailwindcss/language-server \
    emmet-ls \
    prettier

# Lua language server
RUN mkdir -p /opt/lua-language-server && \
    cd /opt/lua-language-server && \
    wget https://github.com/sumneko/lua-language-server/releases/download/3.6.25/lua-language-server-3.6.25-linux-x64.tar.gz && \
    tar -xzf lua-language-server-3.6.25-linux-x64.tar.gz && \
    rm lua-language-server-3.6.25-linux-x64.tar.gz

# Preload Neovim plugins
RUN nvim --headless "+Lazy! sync" +qa || true && \
    nvim --headless ":TSUpdate all" +qa || true

WORKDIR /projects

ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    PATH="/opt/lua-language-server/bin:/usr/local/bin:/root/.dotnet/tools:$PATH"

SHELL ["/bin/zsh", "-c"]

# Startup script
CMD ["container_startup_script.sh"]
