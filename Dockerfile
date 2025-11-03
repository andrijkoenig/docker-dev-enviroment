# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV NVIM_CONFIG_REPO=https://github.com/andrijkoenig/.config.git
ENV NVIM_CONFIG_DIR=/root/.config
ENV PATH="/opt/lua-language-server:/usr/local/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget xclip xsel git unzip ca-certificates gnupg lsb-release \
    build-essential ninja-build gettext cmake clangd \
    ripgrep fzf tree tmux htop python3-pip zsh \
    && rm -rf /var/lib/apt/lists/*
	
	
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y dotnet-sdk-9.0 && \
    rm packages-microsoft-prod.deb && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && npm install -g @angular/cli && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --branch v0.11.4 --depth 1 https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && make CMAKE_BUILD_TYPE=Release && make install && \
    rm -rf /tmp/neovim


RUN git clone --depth 1 $NVIM_CONFIG_REPO $NVIM_CONFIG_DIR && \
    mv $NVIM_CONFIG_DIR/.zshrc /root/.zshrc


RUN npm install -g \
    typescript typescript-language-server \
    @angular/language-server \
    vscode-langservers-extracted \
    @tailwindcss/language-server \
    emmet-ls \
    prettier

# Install Lua Language Server
RUN mkdir -p /opt/lua-language-server && \
    cd /opt/lua-language-server && \
    wget https://github.com/sumneko/lua-language-server/releases/download/3.6.25/lua-language-server-3.6.25-linux-x64.tar.gz && \
    tar -xzf lua-language-server-3.6.25-linux-x64.tar.gz && \
    rm lua-language-server-3.6.25-linux-x64.tar.gz
	
# Roslyn (C#)
RUN curl -LO https://www.nuget.org/api/v2/package/Microsoft.CodeAnalysis.LanguageServer.neutral/5.0.0-1.25277.114 && \
    mkdir -p /opt/roslyn && \
    unzip 5.0.0-1.25277.114 -d /tmp/lsp && \
    mv /tmp/lsp/content/LanguageServer/neutral /opt/roslyn && \
    rm 5.0.0-1.25277.114 && rm -rf /tmp/lsp


RUN nvim --headless "+Lazy! sync" +qa || true && \
    nvim --headless ":TSUpdate all" +qa || true


WORKDIR /root
SHELL ["/bin/zsh", "-c"]
ENTRYPOINT ["nvim"]
