# syntax=docker/dockerfile:1

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
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

# Starship prompt (official installer, non-interactive)
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Provide expected binary names for fd/bat
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    ln -sf /usr/bin/batcat /usr/local/bin/bat

# Node + Angular
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && npm install -g @angular/cli && \
    rm -rf /var/lib/apt/lists/*

# Build & install Neovim
RUN git clone --branch v0.11.5 --depth 1 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && make CMAKE_BUILD_TYPE=Release && make install && \
    rm -rf /tmp/neovim

# Dotfiles (includes Neovim config)
# NOTE: build-time internet is expected; runtime can be offline.
RUN git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"

# Install dotfiles into expected locations (best-effort; doesn't fail build if a file isn't present)
RUN mkdir -p "$XDG_CONFIG_HOME" && \
    if [ -d "$DOTFILES_DIR/.config/nvim" ]; then rm -rf "$XDG_CONFIG_HOME/nvim" && cp -a "$DOTFILES_DIR/.config/nvim" "$XDG_CONFIG_HOME/nvim"; fi && \
    if [ -f "$DOTFILES_DIR/.zshrc" ]; then cp -f "$DOTFILES_DIR/.zshrc" /root/.zshrc; fi && \
    if [ -f "$DOTFILES_DIR/.zprofile" ]; then cp -f "$DOTFILES_DIR/.zprofile" /root/.zprofile; fi && \
    if [ -f "$DOTFILES_DIR/.config/starship.toml" ]; then cp -f "$DOTFILES_DIR/.config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"; fi && \
    if [ -f "$DOTFILES_DIR/.tmux.conf" ]; then cp -f "$DOTFILES_DIR/.tmux.conf" /root/.tmux.conf; fi && \
    if [ -d "$DOTFILES_DIR/.config/tmux" ]; then rm -rf "$XDG_CONFIG_HOME/tmux" && cp -a "$DOTFILES_DIR/.config/tmux" "$XDG_CONFIG_HOME/tmux"; fi

# oh-my-zsh + zinit pre-cloned (so runtime can be offline)
RUN git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git /root/.config/.oh-my-zsh && \
    mkdir -p /root/.local/share/zinit && \
    git clone --depth 1 https://github.com/zdharma-continuum/zinit.git /root/.local/share/zinit/zinit.git

# tmux plugin manager (TPM) pre-cloned for offline tmux
RUN mkdir -p "$XDG_CONFIG_HOME/tmux/plugins" && \
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$XDG_CONFIG_HOME/tmux/plugins/tpm"

# Language servers (Node-based)
RUN npm install -g \
    typescript typescript-language-server \
    @angular/language-server \
    vscode-langservers-extracted \
    @tailwindcss/language-server \
    emmet-ls \
    prettier

# Lua Language Server
RUN mkdir -p /opt/lua-language-server && \
    cd /opt/lua-language-server && \
    wget https://github.com/sumneko/lua-language-server/releases/download/3.6.25/lua-language-server-3.6.25-linux-x64.tar.gz && \
    tar -xzf lua-language-server-3.6.25-linux-x64.tar.gz && \
    rm lua-language-server-3.6.25-linux-x64.tar.gz

# Preload plugins
RUN nvim --headless "+Lazy! sync" +qa || true && \
    nvim --headless ":TSUpdate all" +qa || true

WORKDIR /workspace

ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    PATH="/opt/lua-language-server/bin:/usr/local/bin:/root/.dotnet/tools:$PATH"

SHELL ["/bin/zsh", "-c"]

# Preload zsh plugins (zinit) at build time so runtime can be offline
RUN ZINIT_HOME="/root/.local/share/zinit" \
    ZSH="/root/.config/.oh-my-zsh" \
    ZSH_DISABLE_COMPFIX=true \
    zsh -ic 'exit'

# Startup helper (installed from cloned dotfiles repo; keeps build context clean)
RUN cp "$DOTFILES_DIR/scripts/container_startup_script.sh" /usr/local/bin/container_startup_script.sh && \
    chmod +x /usr/local/bin/container_startup_script.sh

RUN mkdir ~/.ssh 
RUN touch ~/.secrets

ENTRYPOINT ["/usr/local/bin/container_startup_script.sh"]

