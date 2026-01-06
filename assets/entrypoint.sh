#!/bin/bash
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Claude Code Container Entrypoint Script
# This script handles pre-flight checks and initialization of commands

# Function to check for required environment variables
check_required_env_vars() {
    local missing_vars=()

    if [[ -z "$HOST_PWD" ]]; then
        missing_vars+=("HOST_PWD")
    fi

    if [[ -z "$HOST_USER" ]]; then
        missing_vars+=("HOST_USER")
    fi

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "ERROR: Required environment variables are not set!"
        echo "Missing variables: ${missing_vars[*]}"
        echo ""
        echo "Please run the container with:"
        echo "  -e HOST_PWD=\$(pwd)"
        echo "  -e HOST_USER=\$(whoami)"
        echo ""
        echo "Example:"
        echo "  docker run -it --rm \\"
        echo "    -e HOST_PWD=\$(pwd) \\"
        echo "    -e HOST_USER=\$(whoami) \\"
        echo "    [other options...] \\"
        echo "    <image-name>"
        return 1
    fi
    return 0
}

# Function to check for docker-compose.override.yml files
check_no_compose_override() {
    if find /workspace/project -name "docker-compose.override.yml" -type f 2>/dev/null | grep -q .; then
        echo "ERROR: docker-compose.override.yml file found!"
        echo "This file is not allowed in the project directory."
        echo "Please remove any docker-compose.override.yml files before running the container."
        return 1
    fi
    return 0
}

# Run pre-flight checks
echo "Running pre-flight checks..."
CHECKS_FAILED=0

# Check 1: Required environment variables
if ! check_required_env_vars; then
    CHECKS_FAILED=1
fi

# Check 2: No docker-compose.override.yml files
if ! check_no_compose_override; then
    CHECKS_FAILED=1
fi

# Add more checks here as needed in the future
# Example:
# if ! check_something_else; then
#     CHECKS_FAILED=1
# fi

# Exit if any checks failed
if [[ $CHECKS_FAILED -ne 0 ]]; then
    echo ""
    echo "Pre-flight checks FAILED. Container startup aborted."
    exit 1
fi

echo "All pre-flight checks passed."
echo ""

# Update Claude Code to latest version (skip in CI)
if [[ "$CI" != "true" ]]; then
    echo "Checking for Claude Code updates..."
    claude update || true
else
    echo "Claude Code update skipped (CI environment)"
fi

# Auto-detect host user from mounted directory
PROJECT_UID=$(stat -c %u /workspace/project)
PROJECT_GID=$(stat -c %g /workspace/project)

# Continue with normal initialization
echo "Initializing Claude Code container..."

# Check if project has custom commands
if [[ -d "/workspace/project/.claude/commands" ]]; then
    echo "Found project-specific commands in /workspace/project/.claude/commands/"

    # Copy all files and directories from project commands to container commands
    # Using cp -r to preserve directory structure and -n to not overwrite existing files
    cp -rn /workspace/project/.claude/commands/* /workspace/.claude/commands/ 2>/dev/null || true

    echo "Project commands copied to container"
fi

# Check if project has custom bin scripts
if [[ -d "/workspace/project/.claude/bin" ]]; then
    echo "Found project-specific bin scripts in /workspace/project/.claude/bin/"

    # Copy all files from project bin to container bin
    # Using cp -r to preserve directory structure and -n to not overwrite existing files
    cp -rn /workspace/project/.claude/bin/* /workspace/.claude/bin/ 2>/dev/null || true

    echo "Project bin scripts copied to container"
fi

# Check if project has custom skills
if [[ -d "/workspace/project/.claude/skills" ]]; then
    echo "Found project-specific skills in /workspace/project/.claude/skills/"

    # Copy all files from project skills to container bin
    # Using cp -r to preserve directory structure and -n to not overwrite existing files
    cp -rn /workspace/project/.claude/skills/* /workspace/.claude/skills/ 2>/dev/null || true

    echo "Project skills copied to container"
fi

# Check if project has settings.local.json
if [[ -f "/workspace/project/.claude/settings.local.json" ]]; then
    echo "Found project-specific settings in /workspace/project/.claude/settings.local.json"

    # Copy settings.local.json to container if it doesn't exist
    # Using -n to not overwrite existing file
    cp -n /workspace/project/.claude/settings.local.json /workspace/.claude/settings.local.json 2>/dev/null || true

    echo "Project settings copied to container"
fi

# Check if project has custom MCP configuration
if [[ -f "/workspace/project/.claude/.mcp.json" ]]; then
    echo "Found project-specific MCP configuration in /workspace/project/.claude/.mcp.json"

    # Check validity of both JSON files
    CONTAINER_MCP_EXISTS=false
    CONTAINER_MCP_VALID=false
    PROJECT_MCP_VALID=false

    # Check if container MCP file exists and is valid
    if [[ -f "/workspace/.mcp.json" ]]; then
        CONTAINER_MCP_EXISTS=true
        if [[ -s /workspace/.mcp.json ]] && [[ "$(jq type /workspace/.mcp.json 2>/dev/null)" == "\"object\"" ]]; then
            CONTAINER_MCP_VALID=true
        else
            echo "Warning: Container MCP configuration is invalid JSON"
        fi
    else
        echo "No container MCP configuration found"
    fi

    if [[ -s /workspace/project/.claude/.mcp.json ]] && [[ "$(jq type /workspace/project/.claude/.mcp.json 2>/dev/null)" == "\"object\"" ]]; then
        PROJECT_MCP_VALID=true
    else
        echo "Warning: Project MCP configuration is invalid JSON"
    fi

    # Determine merge strategy based on validity
    if [[ "$CONTAINER_MCP_VALID" == "true" ]] && [[ "$PROJECT_MCP_VALID" == "true" ]]; then
        # Both valid - merge them (project takes precedence)
        jq -s '.[0] * .[1]' /workspace/.mcp.json /workspace/project/.claude/.mcp.json > /tmp/merged.mcp.json

        if [[ -s /tmp/merged.mcp.json ]]; then
            mv /tmp/merged.mcp.json /workspace/.mcp.json
            echo "MCP configurations merged successfully"
        else
            echo "Warning: MCP merge resulted in empty file, keeping original configuration"
        fi
    elif [[ "$PROJECT_MCP_VALID" == "true" ]]; then
        # Only project is valid - use it
        cp /workspace/project/.claude/.mcp.json /workspace/.mcp.json
        if [[ "$CONTAINER_MCP_EXISTS" == "false" ]]; then
            echo "Using project MCP configuration (no container config)"
        else
            echo "Using project MCP configuration (container config was invalid)"
        fi
    elif [[ "$CONTAINER_MCP_VALID" == "true" ]]; then
        # Only container is valid - keep it
        echo "Keeping container MCP configuration (project config was invalid)"
    else
        # Handle case where no valid config exists
        if [[ "$CONTAINER_MCP_EXISTS" == "false" ]]; then
            echo "Warning: No valid MCP configuration found - Claude Code may not have MCP server access"
        else
            echo "Warning: Both MCP configurations invalid, keeping original container configuration"
        fi
    fi
elif [[ ! -f "/workspace/.mcp.json" ]]; then
    # No project MCP file and no container MCP file
    echo "Warning: No MCP configuration found - Claude Code will run without MCP servers"
fi

# Initialize Playwright test directory if needed
if [[ ! -d "/Users/claude-code/tests/playwright" ]]; then
    echo "Creating Playwright test directory structure..."
    mkdir -p /Users/claude-code/tests/playwright
fi

# Create screenshots directory for Playwright MCP output
if [[ ! -d "/Users/claude-code/screenshots" ]]; then
    echo "Creating Playwright screenshots directory..."
    mkdir -p /Users/claude-code/screenshots
fi

# Copy example test if it doesn't exist
if [[ ! -f "/Users/claude-code/tests/playwright/example.spec.ts" ]]; then
    echo "Copying example Playwright test..."
    cp /workspace/playwright-templates/example.spec.ts /Users/claude-code/tests/playwright/
fi

# Copy Playwright configuration files if they don't exist
if [[ ! -f "/Users/claude-code/tests/package.json" ]]; then
    echo "Copying Playwright package.json..."
    cp /workspace/playwright-templates/package.json /Users/claude-code/tests/
fi

if [[ ! -f "/Users/claude-code/tests/playwright.config.ts" ]]; then
    echo "Copying Playwright configuration..."
    cp /workspace/playwright-templates/playwright.config.ts /Users/claude-code/tests/
fi

# Skip user switching in CI environments or if running as root
if [[ "$CI" == "true" ]] || [[ "$RUN_AS_ROOT" == "true" ]] || [[ $PROJECT_UID -eq 0 ]]; then
    echo "Running as root..."
    exec "$@"
else
    USERNAME=${HOST_USER:-claude}

    echo "Setting up user $USERNAME with UID $PROJECT_UID and GID $PROJECT_GID..."

    # Change docker group GID to match host's docker socket GID
    DOCKER_GID=$(stat -c %g /var/run/docker.sock)
    groupmod -g "$DOCKER_GID" docker 2>/dev/null || true

    # Create user's group and user (use same name as username)
    getent group "$PROJECT_GID" >/dev/null 2>&1 || groupadd -g "$PROJECT_GID" "$USERNAME"
    if ! id -u "$USERNAME" >/dev/null 2>&1; then
        useradd -u "$PROJECT_UID" -g "$PROJECT_GID" -G docker -m -s /bin/bash "$USERNAME"
    fi

    # Set up Claude configuration links
    mkdir -p "/home/$USERNAME"
    ln -sf /opt/user-claude/.claude.json "/home/$USERNAME/.claude.json"
    ln -sf /opt/user-claude/.claude "/home/$USERNAME/.claude"

    # Set up git configuration link if mounted
    if [[ -f "/opt/user-gitconfig/.gitconfig" ]]; then
        ln -sf /opt/user-gitconfig/.gitconfig "/home/$USERNAME/.gitconfig"
        echo "Git config linked from /opt/user-gitconfig/.gitconfig"
    fi

    # Fix ownership of ALL directories (handles previous root-owned files)
    chown -R "$PROJECT_UID:$PROJECT_GID" "/home/$USERNAME"
    chown -R "$PROJECT_UID:$PROJECT_GID" /workspace
    chown -R "$PROJECT_UID:$PROJECT_GID" /Users/claude-code
    chown -R "$PROJECT_UID:$PROJECT_GID" /opt/user-claude

    echo "Switching to user $USERNAME..."
    exec gosu "$USERNAME" "$@"
fi
