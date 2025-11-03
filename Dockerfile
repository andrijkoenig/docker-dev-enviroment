# syntax=docker/dockerfile:1

# Stage 1: Build Neovim from source
FROM debian:bookworm-slim AS build-nvim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git cmake gettext ninja-build build-essential curl && \
    git clone --branch v0.11.4 --depth 1 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && make CMAKE_BUILD_TYPE=Release && make install DESTDIR=/out && \
    rm -rf /tmp/neovim /var/lib/apt/lists/*

# Stage 2: Final image
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV NVIM_CONFIG_REPO=https://github.com/andrijkoenig/.config.git
ENV NVIM_CONFIG_DIR=/root/.config
ENV PATH="/usr/local/bin:/opt/lua-language-server/bin:$PATH"

# Install essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git unzip ca-certificates gnupg lsb-release \
    build-essential ninja-build gettext cmake clangd \
    ripgrep fzf tree tmux htop zsh \
    dotnet-sdk-9.0 nodejs openjdk-17-jdk && \
    npm install -g @angular/cli && \
    rm -rf /var/lib/apt/lists/*

# Copy Neovim from build stage
COPY --from=build-nvim /out/usr/local /usr/local

# Clone config
RUN git clone --depth 1 $NVIM_CONFIG_REPO $NVIM_CONFIG_DIR && \
    mv $NVIM_CONFIG_DIR/.zshrc /root/.zshrc

# Clipboard (Windows)
RUN curl -L -o /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip && \
    unzip /tmp/win32yank.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/win32yank.exe && \
    rm /tmp/win32yank.zip

# Install LSPs
RUN npm install -g \
    typescript \
    typescript-language-server \
    @angular/language-server \
    vscode-langservers-extracted \
    @tailwindcss/language-server \
    emmet-ls \
    prettier

# Lua Language Server
RUN curl -LO https://github.com/LuaLS/lua-language-server/releases/download/3.15.0/lua-language-server-3.15.0-linux-x64.tar.gz && \
    mkdir -p /opt/lua-language-server && \
    tar -xzf lua-language-server-3.15.0-linux-x64.tar.gz -C /opt/lua-language-server --strip-components=1 && \
    chmod +x /opt/lua-language-server/bin/lua-language-server && \
    rm lua-language-server-3.15.0-linux-x64.tar.gz

# Roslyn (C#)
RUN mkdir -p /opt/roslyn && \
    curl -L -o roslyn.zip https://www.nuget.org/api/v2/package/Microsoft.CodeAnalysis.LanguageServer.neutral/5.0.0-1.25277.114 && \
    unzip roslyn.zip -d /opt/roslyn && \
    find /opt/roslyn -name LanguageServer -type d -exec mv {} /opt/roslyn/server \; && \
    rm roslyn.zip

# Preload plugins and Treesitter
RUN nvim --headless "+Lazy! sync" +qa || true && \
    nvim --headless ":TSUpdateSync all" +qa || true

# Cleanup
RUN rm -rf /tmp/* /var/tmp/*

# Defaults
WORKDIR /workspace
SHELL ["/bin/zsh", "-c"]
ENTRYPOINT ["/bin/zsh", "-c"]
CMD ["nvim"]
