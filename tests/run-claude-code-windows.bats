#!/usr/bin/env bats

# Tests for bin/run-claude-code.ps1 (Windows PowerShell launcher)
# Requires pwsh (PowerShell Core) — tests skip gracefully if not installed.

load test_helper

PS1_SCRIPT="$BATS_TEST_DIRNAME/../bin/run-claude-code.ps1"

setup() {
    create_test_workspace

    # Skip the entire test if pwsh is not available
    if ! command -v pwsh &>/dev/null; then
        skip "pwsh (PowerShell Core) is not installed"
    fi

    # Fixed path for tracking docker calls
    export DOCKER_CALL_LOG="/tmp/test-docker-calls-ps1-$$"

    # Create a temporary bin directory for mock commands
    export MOCK_BIN="/tmp/test-mock-bin-ps1-$$"
    mkdir -p "$MOCK_BIN"

    # Create mock docker command that succeeds by default
    cat > "$MOCK_BIN/docker" << 'MOCK'
#!/bin/bash
echo "$@" >> "$DOCKER_CALL_LOG"
exit 0
MOCK
    chmod +x "$MOCK_BIN/docker"

    # Test home directory for isolation
    export TEST_HOME="/tmp/test-ps1-home-$$"
    mkdir -p "$TEST_HOME"

    # Ensure mock docker is found first
    export PATH="$MOCK_BIN:$PATH"

    # Clean up docker call log
    rm -f "$DOCKER_CALL_LOG"
}

teardown() {
    cleanup_test_workspace
    rm -rf "$MOCK_BIN"
    rm -rf "$TEST_HOME"
    rm -f "$DOCKER_CALL_LOG"
}

# Helper to invoke the PowerShell script with test overrides
run_ps1() {
    run pwsh -NoProfile -NonInteractive -Command "
        \$env:CLAUDE_TEST_USERPROFILE = '$TEST_HOME'
        \$env:CLAUDE_TEST_IMAGE = 'wraithrmm/claude-code-docker:latest'
        \$env:USERNAME = 'testuser'
        & '$PS1_SCRIPT' $*
    "
}

# ---------------------------------------------------------------------------
# 1. Syntax validation
# ---------------------------------------------------------------------------
@test "ps1: script has no syntax errors" {
    run pwsh -NoProfile -NonInteractive -Command "
        \$tokens = \$null
        \$parseErrors = \$null
        [System.Management.Automation.Language.Parser]::ParseFile('$PS1_SCRIPT', [ref]\$tokens, [ref]\$parseErrors)
        if (\$parseErrors.Count -gt 0) {
            \$parseErrors | ForEach-Object { Write-Output \$_.ToString() }
            exit 1
        }
        Write-Output 'No syntax errors'
    "
    assert_success
    assert_output_contains "No syntax errors"
}

# ---------------------------------------------------------------------------
# 2. No PowerShell 7-only syntax
# ---------------------------------------------------------------------------
@test "ps1: no PowerShell 7-only syntax" {
    # Check for null-coalescing (??) operator
    if grep -P '\?\?' "$PS1_SCRIPT" | grep -v '^#' | grep -v '<#' | grep -qv 'ErrorAction'; then
        echo "Found ?? (null-coalescing) operator — not available in PS 5.1" >&2
        return 1
    fi
    # Check for ternary operator pattern (condition ? value : value)
    if grep -P '\?\s+[^@].*\s+:\s+' "$PS1_SCRIPT" | grep -v '^#' | grep -v '<#' | grep -qv 'param'; then
        echo "Found potential ternary operator — not available in PS 5.1" >&2
        return 1
    fi
    # Check for pipeline chain operators (&& ||) used as PS operators
    if grep -P '(?<!\$)\|\|' "$PS1_SCRIPT" | grep -v '^#' | grep -qv '<#'; then
        echo "Found || (pipeline chain) operator — not available in PS 5.1" >&2
        return 1
    fi
    if grep -P '(?<![&])\&\&(?![&])' "$PS1_SCRIPT" | grep -v '^#' | grep -qv '<#'; then
        echo "Found && (pipeline chain) operator — not available in PS 5.1" >&2
        return 1
    fi
}

# ---------------------------------------------------------------------------
# 3. Help output (-Help)
# ---------------------------------------------------------------------------
@test "ps1: -Help shows usage information" {
    run_ps1 -Help

    assert_success
    assert_output_contains "run-claude-code.ps1"
    assert_output_contains "-HostNetwork"
    assert_output_contains "-NoDockerSock"
    assert_output_contains "-NoPull"
    assert_output_contains "-OAuthPort"
    assert_output_contains "-DryRun"
    assert_output_contains "-Help"
    assert_output_contains "USERPROFILE"
    assert_output_contains "C:\\Users\\claude-code"
}

# ---------------------------------------------------------------------------
# 4. Help via --help alias
# ---------------------------------------------------------------------------
@test "ps1: --help alias shows usage information" {
    run pwsh -NoProfile -NonInteractive -Command "
        \$env:CLAUDE_TEST_USERPROFILE = '$TEST_HOME'
        & '$PS1_SCRIPT' --help
    "

    assert_success
    assert_output_contains "run-claude-code.ps1"
    assert_output_contains "-HostNetwork"
}

# ---------------------------------------------------------------------------
# 5. Dry-run default (with pull)
# ---------------------------------------------------------------------------
@test "ps1: -DryRun shows docker pull would execute" {
    run_ps1 -DryRun

    assert_success
    assert_output_contains "Would execute: docker pull"
}

# ---------------------------------------------------------------------------
# 6. Dry-run with -NoPull
# ---------------------------------------------------------------------------
@test "ps1: -DryRun -NoPull shows pull would be skipped" {
    run_ps1 -DryRun -NoPull

    assert_success
    assert_output_contains "Would skip: docker pull"
}

# ---------------------------------------------------------------------------
# 7. Dry-run includes volume mounts
# ---------------------------------------------------------------------------
@test "ps1: -DryRun output includes volume mounts" {
    run_ps1 -DryRun

    assert_success
    assert_output_contains "/workspace/project"
    assert_output_contains ".claude.json"
    assert_output_contains "/root/.claude"
}

# ---------------------------------------------------------------------------
# 8. Dry-run includes environment variables
# ---------------------------------------------------------------------------
@test "ps1: -DryRun output includes environment variables" {
    run_ps1 -DryRun

    assert_success
    assert_output_contains "HOST_PWD="
    assert_output_contains "HOST_USER="
    assert_output_contains "RUN_AS_ROOT=true"
}

# ---------------------------------------------------------------------------
# 9. Dry-run includes image name
# ---------------------------------------------------------------------------
@test "ps1: -DryRun output includes image name" {
    run_ps1 -DryRun

    assert_success
    assert_output_contains "wraithrmm/claude-code-docker:latest"
}

# ---------------------------------------------------------------------------
# 10. Dry-run with -HostNetwork
# ---------------------------------------------------------------------------
@test "ps1: -DryRun -HostNetwork includes --network host" {
    run_ps1 -DryRun -HostNetwork

    assert_success
    assert_output_contains "--network host"
}

# ---------------------------------------------------------------------------
# 11. Dry-run with -NoDockerSock
# ---------------------------------------------------------------------------
@test "ps1: -DryRun -NoDockerSock excludes docker socket mount" {
    run_ps1 -DryRun -NoDockerSock

    assert_success
    refute_output_contains "docker_engine"
    refute_output_contains "docker.sock"
}

# ---------------------------------------------------------------------------
# 12. Dry-run with -OAuthPort 5555
# ---------------------------------------------------------------------------
@test "ps1: -DryRun -OAuthPort 5555 maps correct port" {
    run_ps1 -DryRun -OAuthPort 5555

    assert_success
    assert_output_contains "5555:3334"
}

# ---------------------------------------------------------------------------
# 13. Kebab-case aliases work
# ---------------------------------------------------------------------------
@test "ps1: kebab-case aliases --dry-run --no-pull work" {
    run pwsh -NoProfile -NonInteractive -Command "
        \$env:CLAUDE_TEST_USERPROFILE = '$TEST_HOME'
        \$env:CLAUDE_TEST_IMAGE = 'wraithrmm/claude-code-docker:latest'
        \$env:USERNAME = 'testuser'
        & '$PS1_SCRIPT' --dry-run --no-pull
    "

    assert_success
    assert_output_contains "Would skip: docker pull"
    assert_output_contains "Would execute:"
}

# ---------------------------------------------------------------------------
# 14. Invalid port rejected
# ---------------------------------------------------------------------------
@test "ps1: -OAuthPort 0 is rejected" {
    run_ps1 -DryRun -OAuthPort 0

    assert_failure
    assert_output_contains "Invalid port number"
}

@test "ps1: -OAuthPort 99999 is rejected" {
    run_ps1 -DryRun -OAuthPort 99999

    assert_failure
    assert_output_contains "Invalid port number"
}

# ---------------------------------------------------------------------------
# 15. Missing docker error
# ---------------------------------------------------------------------------
@test "ps1: error message when docker is not found" {
    run pwsh -NoProfile -NonInteractive -Command "
        \$env:CLAUDE_TEST_USERPROFILE = '$TEST_HOME'
        \$env:USERNAME = 'testuser'
        \$env:PATH = '/nonexistent'
        & '$PS1_SCRIPT'
    "

    assert_failure
    assert_output_contains "Docker is not installed"
}

# ---------------------------------------------------------------------------
# 16. Dependency creation
# ---------------------------------------------------------------------------
@test "ps1: creates .claude.json and .claude/ under test home" {
    # Ensure they don't exist yet
    rm -f "$TEST_HOME/.claude.json"
    rm -rf "$TEST_HOME/.claude"

    run_ps1 -DryRun

    assert_success
    assert_file_exists "$TEST_HOME/.claude.json"
    assert_dir_exists "$TEST_HOME/.claude"
}
