# Use Ubuntu 24.04 as base (matching your target)
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Linux Dependencies & Utilities
RUN apt-get update && apt-get install -y \
    build-essential \
    libgtk-3-dev \
    libwebkit2gtk-4.1-dev \
    curl \
    wget \
    git \
    rpm \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Go 1.24
COPY --from=golang:1.24 /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# 3. Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# 4. Install Wails & nFPM
# We install them to a global location so they are ready to use
RUN go install github.com/wailsapp/wails/v2/cmd/wails@latest \
    && go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest

# Verify installations
RUN wails version && nfpm --version && go version && node -v
