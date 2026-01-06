#!/bin/bash

# Test helper functions for entrypoint.sh tests

export TEST_WORKSPACE="/tmp/test-workspace-$$"
export TEST_PROJECT="/tmp/test-project-$$"
export TEST_CLAUDE_CODE="/tmp/test-claude-code-$$"
export ORIGINAL_ENTRYPOINT="$BATS_TEST_DIRNAME/../assets/entrypoint.sh"

# Load additional helper modules if they exist
if [[ -f "$BATS_TEST_DIRNAME/test_helper_ai_playground.bash" ]]; then
    source "$BATS_TEST_DIRNAME/test_helper_ai_playground.bash"
fi

if [[ -f "$BATS_TEST_DIRNAME/test_helper_json.bash" ]]; then
    source "$BATS_TEST_DIRNAME/test_helper_json.bash"
fi

if [[ -f "$BATS_TEST_DIRNAME/test_helper_output.bash" ]]; then
    source "$BATS_TEST_DIRNAME/test_helper_output.bash"
fi

# Setup function - called before each test
setup() {
    create_test_workspace
}

# Teardown function - called after each test
teardown() {
    cleanup_test_workspace
}

# Create a clean test workspace
create_test_workspace() {
    rm -rf "$TEST_WORKSPACE" "$TEST_PROJECT" "$TEST_CLAUDE_CODE"
    mkdir -p "$TEST_WORKSPACE/.claude/commands"
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    mkdir -p "$TEST_WORKSPACE/.claude/skills"
    mkdir -p "$TEST_PROJECT"
    mkdir -p "$TEST_CLAUDE_CODE"
}

# Clean up test workspace
cleanup_test_workspace() {
    rm -rf "$TEST_WORKSPACE" "$TEST_PROJECT" "$TEST_CLAUDE_CODE"
    rm -f /tmp/test-entrypoint-$$.sh
}

# Run the entrypoint script with mocked paths
run_entrypoint() {
    # Create a modified version of the entrypoint script with test paths
    sed -e "s|/workspace/project|$TEST_PROJECT|g" \
        -e "s|/workspace|$TEST_WORKSPACE|g" \
        -e "s|/Users/claude-code|$TEST_CLAUDE_CODE|g" \
        "$ORIGINAL_ENTRYPOINT" > "/tmp/test-entrypoint-$$.sh"
    chmod +x "/tmp/test-entrypoint-$$.sh"
    # Clear HOST_PWD and HOST_USER to ensure clean test environment
    run env -u HOST_PWD -u HOST_USER "/tmp/test-entrypoint-$$.sh" "$@"
}

# Run the entrypoint script with specific environment variables
run_entrypoint_with_env() {
    local env_vars=()
    # Process environment variable arguments until we hit a non-env argument
    while [[ $# -gt 0 && "$1" =~ ^[A-Z_]+= ]]; do
        env_vars+=("$1")
        shift
    done
    
    # Create a modified version of the entrypoint script with test paths
    sed -e "s|/workspace/project|$TEST_PROJECT|g" \
        -e "s|/workspace|$TEST_WORKSPACE|g" \
        -e "s|/Users/claude-code|$TEST_CLAUDE_CODE|g" \
        "$ORIGINAL_ENTRYPOINT" > "/tmp/test-entrypoint-$$.sh"
    chmod +x "/tmp/test-entrypoint-$$.sh"
    
    # Run with specified environment, clearing HOST_PWD and HOST_USER first
    if [[ ${#env_vars[@]} -gt 0 ]]; then
        run env -u HOST_PWD -u HOST_USER "${env_vars[@]}" "/tmp/test-entrypoint-$$.sh" "$@"
    else
        run env -u HOST_PWD -u HOST_USER "/tmp/test-entrypoint-$$.sh" "$@"
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    [[ -f "$file" ]] || { echo "File does not exist: $file" >&2; return 1; }
}

# Assert that a file does not exist
assert_file_not_exists() {
    local file="$1"
    [[ ! -f "$file" ]] || { echo "File should not exist: $file" >&2; return 1; }
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]] || { echo "Directory does not exist: $dir" >&2; return 1; }
}

# Assert that a file contains specific content
assert_file_contains() {
    local file="$1"
    local content="$2"
    grep -q "$content" "$file" || { echo "File $file does not contain: $content" >&2; return 1; }
}

# Assert that a file does not contain specific content
refute_file_contains() {
    local file="$1"
    local content="$2"
    ! grep -q "$content" "$file" || { echo "File $file contains unexpected: $content" >&2; return 1; }
}

# Assert that a file is executable
assert_file_executable() {
    local file="$1"
    [[ -x "$file" ]] || { echo "File is not executable: $file" >&2; return 1; }
}

# Assert that output contains a string
assert_output_contains() {
    local expected="$1"
    echo "$output" | grep -F -q -- "$expected" || { echo "Output does not contain: $expected" >&2; echo "Actual output: $output" >&2; return 1; }
}

# Assert that output exactly matches expected string
assert_output() {
    local expected="$1"
    [[ "$output" == "$expected" ]] || { echo "Expected: $expected" >&2; echo "Actual: $output" >&2; return 1; }
}

# Assert that output does not contain a string
refute_output_contains() {
    local unexpected="$1"
    ! echo "$output" | grep -F -q -- "$unexpected" || { echo "Output contains unexpected: $unexpected" >&2; echo "Actual output: $output" >&2; return 1; }
}

# Assert success (exit code 0)
assert_success() {
    [[ "$status" -eq 0 ]] || { echo "Expected success but got exit code: $status" >&2; echo "Output: $output" >&2; return 1; }
}

# Assert failure (non-zero exit code)
assert_failure() {
    [[ "$status" -ne 0 ]] || { echo "Expected failure but got success" >&2; echo "Output: $output" >&2; return 1; }
}

# Assert specific exit code
assert_exit_code() {
    local expected="$1"
    [[ "$status" -eq "$expected" ]] || { echo "Expected exit code $expected but got: $status" >&2; echo "Output: $output" >&2; return 1; }
}

# Create a file with content
create_file() {
    local file="$1"
    local content="$2"
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
}

# Make a file executable
make_executable() {
    local file="$1"
    chmod +x "$file"
}