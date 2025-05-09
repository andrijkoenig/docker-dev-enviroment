# 🛠 My Dev Environment (Docker)

A containerized Neovim setup for a consistent, plugin-rich development environment.

## 🚀 Quick Start

### Build the image
```bash
docker build -t andrijkoenig/dev-env .
```

### Pull the image
```bash
docker pull andrijkoenig/dev-env:latest
```

### Run the image with the current path mounted (windows)
```bash
docker run -it --rm -v $pwd/:/home/devuser/project -p 4200:4200 andrijkoenig/dev-env:lates
```