#!/bin/bash

# Claude Code Wrapper Script
# This script provides a convenient CLI wrapper for running Claude Code
# with support for MCP configuration control

set -e

# MCP configuration paths
FULL_MCP_CONFIG="/workspace/.mcp.json"
EMPTY_MCP_CONFIG="/tmp/empty-mcp.json"

# Function to display help message
show_help() {
    cat << EOF
Claude Code Wrapper

Usage:
  claude-wrapper [options] [arguments]

Description:
  A wrapper script for running Claude Code in a containerized environment.
  By default, Claude Code runs WITHOUT MCP servers to improve startup time
  and reduce resource usage.

Wrapper Options:
  -h, --help           Show this help message
  --with-mcp=all       Load all MCP servers from container configuration
  --with-mcp=<name>    Load specific MCP configuration (future enhancement)

Examples:
  claude-wrapper                    # Start Claude Code without MCP servers
  claude-wrapper --with-mcp=all     # Start Claude Code with all MCP servers
  claude-wrapper --help             # Show Claude Code help
  claude-wrapper --version          # Show Claude Code version

MCP Configuration:
  - Default: No MCP servers loaded (faster startup)
  - With --with-mcp=all: Loads all servers from $FULL_MCP_CONFIG

EOF
}

# Function to create empty MCP configuration
create_empty_mcp_config() {
    cat > "$EMPTY_MCP_CONFIG" << 'EOF'
{
  "mcpServers": {}
}
EOF
}

# Function to run Claude (main functionality)
run_claude() {
    local use_mcp="$1"
    shift

    # Create empty MCP config if it doesn't exist
    if [[ ! -f "$EMPTY_MCP_CONFIG" ]]; then
        create_empty_mcp_config
    fi

    # Determine which MCP config to use
    local mcp_config="$EMPTY_MCP_CONFIG"
    if [[ "$use_mcp" == "all" ]]; then
        if [[ -f "$FULL_MCP_CONFIG" ]]; then
            mcp_config="$FULL_MCP_CONFIG"
            echo "Loading MCP servers from: $FULL_MCP_CONFIG"
        else
            echo "Warning: MCP config not found at $FULL_MCP_CONFIG, running without MCP servers"
        fi
    else
        echo "Running Claude Code without MCP servers (use --with-mcp=all to enable)"
    fi

    # Run claude with the selected MCP configuration
    exec claude --mcp-config "$mcp_config" "$@"
}

# Main script logic
main() {
    local use_mcp=""
    local claude_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                # If it's the only argument, show wrapper help
                if [[ ${#claude_args[@]} -eq 0 ]] && [[ $# -eq 1 ]]; then
                    show_help
                    exit 0
                else
                    # Otherwise, pass to claude
                    claude_args+=("$1")
                fi
                ;;
            --with-mcp=*)
                # Extract MCP configuration name
                use_mcp="${1#*=}"
                ;;
            *)
                # Collect all other arguments for claude
                claude_args+=("$1")
                ;;
        esac
        shift
    done

    # Run claude with parsed configuration
    run_claude "$use_mcp" "${claude_args[@]}"
}

# Run main function with all script arguments
main "$@"
