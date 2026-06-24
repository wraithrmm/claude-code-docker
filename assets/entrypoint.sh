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

# Decide which of the configured MCP servers Claude Code loads and auto-approves.
# Selected servers go into enabledMcpjsonServers (loaded and pre-approved, so no
# interactive trust prompt can block this session or any agent it spawns); every
# other configured server goes into disabledMcpjsonServers (never loaded, never
# prompted), keeping unused servers from consuming context. Selection precedence:
#   1. CLAUDE_MCP_SERVERS env (comma-separated names, "all", or "none")
#   2. interactive tick-list when a terminal is attached
#   3. "none" otherwise (non-interactive / CI)
prompt_mcp_selection() {
    local servers="$1"
    local -a available=()
    mapfile -t available <<< "$servers"

    {
        printf '\n'
        printf 'Configured MCP servers (each one loaded consumes context):\n'
        local idx=1 name
        for name in "${available[@]}"; do
            printf '  %d) %s\n' "$idx" "$name"
            idx=$((idx + 1))
        done
        printf 'Enable which? comma-separated numbers or names, "all", or Enter for none: '
    } > /dev/tty

    local reply
    read -r reply < /dev/tty || reply=""

    case "$reply" in
        all|ALL) printf 'all'; return 0 ;;
        "") printf 'none'; return 0 ;;
    esac

    local resolved="" token name
    local -a tokens=()
    IFS=',' read -ra tokens <<< "$reply"
    for token in "${tokens[@]}"; do
        token="${token//[[:space:]]/}"
        [[ -z "$token" ]] && continue
        if [[ "$token" =~ ^[0-9]+$ ]]; then
            name="${available[$((token - 1))]:-}"
        else
            name="$token"
        fi
        [[ -n "$name" ]] && resolved="${resolved:+$resolved,}$name"
    done
    printf '%s' "${resolved:-none}"
}

configure_mcp_selection() {
    local mcp_file="/workspace/.mcp.json"
    local settings_file="/workspace/.claude/settings.json"

    [[ -s "$mcp_file" ]] || return 0
    local all_servers
    all_servers=$(jq -r '.mcpServers // {} | keys[]' "$mcp_file" 2>/dev/null) || return 0
    [[ -n "$all_servers" ]] || return 0

    local selection
    if [[ -n "$CLAUDE_MCP_SERVERS" ]]; then
        selection="$CLAUDE_MCP_SERVERS"
        echo "MCP selection provided via CLAUDE_MCP_SERVERS: $selection"
    elif [[ "$CI" != "true" && -t 0 && -t 1 ]]; then
        selection=$(prompt_mcp_selection "$all_servers")
    else
        selection="none"
    fi

    local enabled_csv
    case "$selection" in
        all|ALL) enabled_csv=$(printf '%s' "$all_servers" | paste -sd, -) ;;
        none|NONE|"") enabled_csv="" ;;
        *) enabled_csv="$selection" ;;
    esac

    local all_json wanted_json enabled_json disabled_json
    all_json=$(printf '%s\n' "$all_servers" | jq -R . | jq -s 'map(select(. != ""))')
    wanted_json=$(jq -cn --arg csv "$enabled_csv" \
        '[$csv | split(",")[] | gsub("^\\s+|\\s+$"; "")] | map(select(length > 0))')
    enabled_json=$(jq -cn --argjson all "$all_json" --argjson want "$wanted_json" \
        '$all | map(select(. as $s | $want | index($s)))')
    disabled_json=$(jq -cn --argjson all "$all_json" --argjson en "$enabled_json" \
        '$all - $en')

    mkdir -p "$(dirname "$settings_file")"
    if [[ -s "$settings_file" ]] && jq empty "$settings_file" 2>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --argjson en "$enabled_json" --argjson dis "$disabled_json" \
           '. + {enableAllProjectMcpServers: false, enabledMcpjsonServers: $en, disabledMcpjsonServers: $dis}' \
           "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
    else
        jq -n --argjson en "$enabled_json" --argjson dis "$disabled_json" \
           '{enableAllProjectMcpServers: false, enabledMcpjsonServers: $en, disabledMcpjsonServers: $dis}' \
           > "$settings_file"
    fi

    echo "Configured MCP auto-approval: enabled=[$(printf '%s' "$enabled_json" | jq -r 'join(",")')] disabled=[$(printf '%s' "$disabled_json" | jq -r 'join(",")')]"
}

configure_mcp_selection

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

# Add project bin scripts to PATH for convenient access
export PATH="/workspace/project/.claude/bin:/workspace/.claude/bin:$PATH"

# Pin the workflow project root to the mounted codebase. The claude-workflow scripts
# default PROJECT_ROOT to "git rev-parse --show-toplevel || pwd", which resolves to
# /workspace when invoked from the container's default working directory, placing
# ai-playground at /workspace/ai-playground. The codebase is always mounted at
# /workspace/project, so pin it there (overridable) to keep ai-playground under it.
export PROJECT_ROOT="${PROJECT_ROOT:-/workspace/project}"

# Clear spurious "modified" flags left over from sharing a checkout between a
# Windows host and this Linux container. The system-wide git config baked into
# the image (core.autocrlf=input, core.filemode=false) makes git ignore CRLF/LF
# and executable-bit differences, but files already flagged in `git status` keep
# showing until the index stat cache is refreshed. This refreshes only the files
# git flags that have no real content change (pure line-ending noise); files with
# genuine edits are left untouched and unstaged. Accepts an optional runner prefix
# (e.g. "gosu user") so it can run as the user that owns the repo.
normalize_project_eol() {
    local git_cmd=("$@" git -C /workspace/project)
    "${git_cmd[@]}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    echo "Normalizing git line-endings for shared Windows/Linux checkout..."
    "${git_cmd[@]}" ls-files -m 2>/dev/null | while IFS= read -r changed_file; do
        if "${git_cmd[@]}" diff --quiet -- "$changed_file" 2>/dev/null; then
            "${git_cmd[@]}" add --renormalize -- "$changed_file" >/dev/null 2>&1 || true
        fi
    done
}

# Skip user switching in CI environments or if running as root
if [[ "$CI" == "true" ]] || [[ "$RUN_AS_ROOT" == "true" ]] || [[ $PROJECT_UID -eq 0 ]]; then
    echo "Running as root..."
    normalize_project_eol
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

    # Run as the repo-owning user so git does not reject the repo as
    # "dubious ownership" and so the index it rewrites stays user-owned.
    normalize_project_eol gosu "$USERNAME"

    echo "Switching to user $USERNAME..."
    exec gosu "$USERNAME" "$@"
fi
