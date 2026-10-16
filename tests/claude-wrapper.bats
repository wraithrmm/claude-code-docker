#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

load test_helper

WRAPPER="$BATS_TEST_DIRNAME/../assets/claude-wrapper"

setup() {
    create_test_workspace
    export CLAUDE_REAL_BIN="$TEST_CLAUDE_CODE/real-claude"
    export CLAUDE_PROJECT_MOUNT="$TEST_PROJECT"
    printf '#!/bin/bash\nprintf "[%%s]" "$@"\n' > "$CLAUDE_REAL_BIN"
    chmod +x "$CLAUDE_REAL_BIN"
}

run_wrapper_in() {
    local dir="$1"
    shift
    run bash -c 'cd "$1" && shift && exec bash "$@"' _ "$dir" "$WRAPPER" "$@"
}

@test "adds the project mount before the caller's arguments" {
    run_wrapper_in "$TEST_WORKSPACE" -p "hello prompt"

    assert_success
    assert_output "[--add-dir=$TEST_PROJECT][-p][hello prompt]"
}

@test "adds the project mount to an interactive session with no arguments" {
    run_wrapper_in "$TEST_WORKSPACE"

    assert_success
    assert_output "[--add-dir=$TEST_PROJECT]"
}

@test "adds the project mount when the first argument is a prompt" {
    run_wrapper_in "$TEST_WORKSPACE" "fix the update script"

    assert_success
    assert_output "[--add-dir=$TEST_PROJECT][fix the update script]"
}

@test "uses the single-value form so a following prompt is not taken as a directory" {
    run_wrapper_in "$TEST_WORKSPACE" "a prompt"

    assert_success
    refute_output_contains "[--add-dir]"
}

@test "leaves subcommands untouched" {
    local subcommand
    for subcommand in update upgrade mcp plugin plugins agents doctor install auth setup-token; do
        run_wrapper_in "$TEST_WORKSPACE" "$subcommand" list
        assert_success
        assert_output "[$subcommand][list]"
    done
}

@test "does not add the mount when the session starts inside the project" {
    mkdir -p "$TEST_PROJECT/src"

    run_wrapper_in "$TEST_PROJECT/src" -p "hi"

    assert_success
    assert_output "[-p][hi]"
}

@test "does not add the mount twice when the caller already passed it" {
    run_wrapper_in "$TEST_WORKSPACE" --add-dir "$TEST_PROJECT" -p "hi"
    assert_success
    assert_output "[--add-dir][$TEST_PROJECT][-p][hi]"

    run_wrapper_in "$TEST_WORKSPACE" "--add-dir=$TEST_PROJECT/"
    assert_success
    assert_output "[--add-dir=$TEST_PROJECT/]"
}

@test "does not add the mount when no project is mounted" {
    rm -rf "$TEST_PROJECT"

    run_wrapper_in "$TEST_WORKSPACE" -p "hi"

    assert_success
    assert_output "[-p][hi]"
}

@test "passes the real binary's exit code through" {
    printf '#!/bin/bash\nexit 7\n' > "$CLAUDE_REAL_BIN"

    run_wrapper_in "$TEST_WORKSPACE" -p "hi"

    assert_exit_code 7
}
