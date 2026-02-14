#!/usr/bin/env bats

# Tests for bin/run-claude-code image pull functionality

load test_helper

ORIGINAL_SCRIPT="$BATS_TEST_DIRNAME/../bin/run-claude-code"

setup() {
    create_test_workspace

    # Fixed path for tracking docker calls (avoids $$ PID mismatch in subprocesses)
    export DOCKER_CALL_LOG="/tmp/test-docker-calls-$$"

    # Create a temporary bin directory for mock commands
    export MOCK_BIN="/tmp/test-mock-bin-$$"
    mkdir -p "$MOCK_BIN"

    # Create mock docker command that succeeds by default
    # Uses DOCKER_CALL_LOG env var (inherited) instead of $$ (which would be the mock's PID)
    cat > "$MOCK_BIN/docker" << 'MOCK'
#!/bin/bash
echo "$@" >> "$DOCKER_CALL_LOG"
exit 0
MOCK
    chmod +x "$MOCK_BIN/docker"

    # Create a modified script that uses our mock docker and skips actual container run
    export TEST_SCRIPT="/tmp/test-run-claude-code-$$.sh"
    sed -e "s|eval \"\$cmd\"|echo \"Would run container\"|g" \
        "$ORIGINAL_SCRIPT" > "$TEST_SCRIPT"
    chmod +x "$TEST_SCRIPT"

    # Clean up docker call log
    rm -f "$DOCKER_CALL_LOG"

    # Ensure mock docker is found first
    export PATH="$MOCK_BIN:$PATH"
}

teardown() {
    cleanup_test_workspace
    rm -rf "$MOCK_BIN"
    rm -f "$TEST_SCRIPT"
    rm -f "$DOCKER_CALL_LOG"
}

@test "run-claude-code: pulls image by default" {
    run "$TEST_SCRIPT"

    assert_success
    assert_output_contains "Checking for updates"
    assert_output_contains "Image up to date"
    # Verify docker pull was called
    assert_file_exists "$DOCKER_CALL_LOG"
    assert_file_contains "$DOCKER_CALL_LOG" "pull wraithrmm/claude-code-docker:latest"
}

@test "run-claude-code: --no-pull skips image pull" {
    run "$TEST_SCRIPT" --no-pull

    assert_success
    assert_output_contains "Skipping image pull (--no-pull)"
    refute_output_contains "Checking for updates"
    # Verify docker pull was NOT called (only docker info should be in log)
    if [[ -f "$DOCKER_CALL_LOG" ]]; then
        refute_file_contains "$DOCKER_CALL_LOG" "pull"
    fi
}

@test "run-claude-code: shows --no-pull hint during pull" {
    run "$TEST_SCRIPT"

    assert_success
    assert_output_contains "Use --no-pull to skip this step"
}

@test "run-claude-code: graceful fallback when pull fails" {
    # Replace mock docker with one that fails on pull
    cat > "$MOCK_BIN/docker" << 'MOCK'
#!/bin/bash
echo "$@" >> "$DOCKER_CALL_LOG"
if [[ "$1" == "pull" ]]; then
    exit 1
fi
exit 0
MOCK
    chmod +x "$MOCK_BIN/docker"

    run "$TEST_SCRIPT"

    assert_success
    assert_output_contains "Warning: Failed to pull latest image. Using cached version if available."
}

@test "run-claude-code: --dry-run shows pull would occur" {
    run "$TEST_SCRIPT" --dry-run

    assert_success
    assert_output_contains "Would execute: docker pull"
}

@test "run-claude-code: --dry-run with --no-pull shows pull would be skipped" {
    run "$TEST_SCRIPT" --dry-run --no-pull

    assert_success
    assert_output_contains "Would skip: docker pull"
}

@test "run-claude-code: --help includes --no-pull" {
    run "$TEST_SCRIPT" --help

    assert_success
    assert_output_contains "--no-pull"
    assert_output_contains "Skip pulling the latest image"
}
