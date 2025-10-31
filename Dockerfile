# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV NVIM_CONFIG_REPO=https://github.com/andrijkoenig/.config.git
ENV NVIM_CONFIG_DIR=/root/.config
ENV PATH="/usr/local/bin:$PATH"

# ==========================================
# 1️⃣ Install essentials
# ==========================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git unzip ca-certificates gnupg lsb-release \
    build-essential ninja-build gettext cmake clangd \
    ripgrep fzf tree tmux htop python3-pip zsh \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# 2️⃣ Install .NET, Node.js, and Java
# ==========================================
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y dotnet-sdk-9.0 && \
    rm packages-microsoft-prod.deb && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && npm install -g @angular/cli && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*

# ==========================================
# 3️⃣ Build Neovim from source
# ==========================================
RUN git clone --branch v0.11.4 --depth 1 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && make CMAKE_BUILD_TYPE=Release && make install && \
    rm -rf /tmp/neovim

# ==========================================
# 4️⃣ Neovim configuration
# ==========================================
RUN git clone --depth 1 $NVIM_CONFIG_REPO $NVIM_CONFIG_DIR && \
    mv $NVIM_CONFIG_DIR/.zshrc /root/.zshrc

RUN pip3 install --break-system-packages pynvim

# ==========================================
# 5️⃣ Install LSPs
# ==========================================
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

# Roslyn (C#)
RUN curl -LO https://www.nuget.org/api/v2/package/Microsoft.CodeAnalysis.LanguageServer.neutral/5.0.0-1.25277.114 && \
    mkdir -p /opt/roslyn && \
    unzip 5.0.0-1.25277.114 -d /tmp/lsp && \
    mv /tmp/lsp/content/LanguageServer/neutral /opt/roslyn && \
    rm 5.0.0-1.25277.114 && rm -rf /tmp/lsp

# ==========================================
# 6️⃣ Preload plugins (for offline use)
# ==========================================
RUN nvim --headless "+Lazy! sync" +qa || true && \
    nvim --headless ":TSUpdate all" +qa || true

# ==========================================
# 7️⃣ Defaults
# ==========================================
WORKDIR /root
SHELL ["/bin/zsh", "-c"]
ENTRYPOINT ["nvim"]

