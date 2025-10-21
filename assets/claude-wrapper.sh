#!/bin/bash

# Claude Code Wrapper Script
# This script provides a convenient CLI wrapper for running Claude Code
# with support for future MCP configuration switching

set -e

# Function to display help message
show_help() {
    cat << EOF
Claude Code Wrapper

Usage:
  claude-wrapper [options] [arguments]

Description:
  A wrapper script for running Claude Code in a containerized environment.
  This script currently passes all arguments directly to Claude Code.

  Future enhancements will include:
  - MCP configuration switching
  - Profile management
  - Helper commands for common tasks

Options:
  -h, --help     Show this help message

Examples:
  claude-wrapper             # Start Claude Code interactively
  claude-wrapper --help      # Show Claude Code help
  claude-wrapper --version   # Show Claude Code version

EOF
}

# Function to run Claude (main functionality)
run_claude() {
    # For now, simply pass all arguments to claude
    exec claude "$@"
}

# Main script logic
main() {
    # Check for help flag
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] && [[ $# -eq 1 ]]; then
        show_help
        exit 0
    fi

    # Future: Add MCP switching logic here
    # Example:
    # case "$1" in
    #     mcp:switch)
    #         switch_mcp_config "$2"
    #         ;;
    #     mcp:list)
    #         list_mcp_configs
    #         ;;
    #     *)
    #         run_claude "$@"
    #         ;;
    # esac

    # For now, just run claude with all arguments
    run_claude "$@"
}

# Run main function with all script arguments
main "$@"
