ARG PHP_VERSION=8.3
ARG OS_RELEASE=-bookworm
# Base image - replace with your PHP/Apache base image
FROM php:${PHP_VERSION}-apache${OS_RELEASE}

ARG TAGGED_VERSION
ARG CACHE_BUST

LABEL "service"="claudecode" \
    "version"="${TAGGED_VERSION}" \
    "org.opencontainers.image.licenses"="PolyForm-Shield-1.0.0" \
    "org.opencontainers.image.title"="Claude Code Docker" \
    "org.opencontainers.image.description"="Containerized Claude Code development environment" \
    "org.opencontainers.image.vendor"="Richard Mann"

# Update and install system packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    fonts-liberation \
    git \
    gnupg \
    gosu \
    gpg \
    jq \
    libasound2 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    libxrandr2 \
    libxss1 \
    lsb-release \
    python-is-python3 \
    python3 \
    python3-pip \
    software-properties-common \
    tree \
    unzip \
    wget \
    xdg-utils && \
    apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

# Install Docker CE (version 24+) and docker-compose to allow claude to run Unit Tests
# Add Docker's official GPG key and repository
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin  && \
    apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    docker --version && \
    docker compose version

# Install Node.js (required for Claude Code)
# Using NodeSource repository for latest LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install --no-install-recommends -y \
    nodejs && \
    apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    node --version && \
    npm --version

# Install Terraform and dependencies
RUN wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
    terraform && \
    apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    pip3 install --no-cache-dir --break-system-packages \
    pre-commit \
    checkov && \
    pip3 install --no-cache-dir --break-system-packages --upgrade asteval>=1.0.6 && \
    curl -sL "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz && tar -xzf terraform-docs.tgz terraform-docs && rm terraform-docs.tgz && chmod +x terraform-docs && mv terraform-docs /usr/bin/ && \
    curl -sL "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && mv tflint /usr/bin/ && \
    curl -sL "$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -o -E -i -m 1 "https://.+?/trivy_.+?_Linux-64bit.tar.gz")" > trivy.tar.gz && tar -xzf trivy.tar.gz trivy && rm trivy.tar.gz && mv trivy /usr/bin && \
    npm install -g markdownlint-cli

# Install Claude Code and dependencies
RUN npm install -g \
    @anthropic-ai/claude-code \
    bats && \
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/bin" sh && \
    claude --version

# Create a workspace directory for Claude Code projects
RUN mkdir -p /workspace
RUN mkdir -p /workspace/project
WORKDIR /workspace

# Install Playwright with TypeScript support
# This replicates your TypeScript choice and browser installation choice
RUN npm install @playwright/test typescript @types/node

# Install Playwright browsers supported on ARM64
# Note: Chrome (Google Chrome) is not available on ARM64 Linux, only Chromium
RUN npx playwright install chromium firefox webkit

# Install system dependencies for browsers
RUN npx playwright install-deps chromium firefox webkit

# Install Playwright MCP server
RUN npm install -g @playwright/mcp@latest

# Verify Playwright MCP installation
RUN npx @playwright/mcp --version || echo "Playwright MCP installed"

# Create a templates directory for Playwright files that will be copied at runtime
RUN mkdir -p /workspace/playwright-templates

# Copy Playwright template files to a staging area
COPY assets/playwright/example.spec.ts /workspace/playwright-templates/example.spec.ts
COPY assets/playwright/playwright.config.ts /workspace/playwright-templates/playwright.config.ts
COPY assets/playwright/package.json /workspace/playwright-templates/package.json

# Set appropriate permissions
RUN chown -R www-data:www-data /workspace

# Create Claude config directory
RUN mkdir -p /root/.claude

# Copy LICENSE file for license compliance
COPY LICENSE /workspace/LICENSE

# Copy CLAUDE.md with Docker-in-Docker instructions to root
COPY assets/CLAUDE.md /workspace/CLAUDE.md

# Copy MCP configuration to workspace (container scope)
# This allows users to mount their own ~/.claude.json with just their API key
# while still having MCP servers configured in the container
# Projects can add additional MCP servers via .claude/.mcp.json
COPY assets/mcp.json /workspace/.mcp.json

# Copy .claude dir to root to share common commands across all Claude Code instances
COPY assets/.claude /workspace/.claude

# Copy entrypoint script
COPY assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy Claude wrapper script to /usr/local/bin (in PATH)
COPY assets/claude-wrapper.sh /usr/local/bin/claude-wrapper
RUN chmod +x /usr/local/bin/claude-wrapper

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
