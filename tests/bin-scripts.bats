#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Load test helper functions
load test_helper

# Override setup to use standardized bin test setup
setup() {
    setup_bin_test
}

# Test: Entrypoint PATH configuration for bin scripts

@test "entrypoint adds project bin to PATH" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/custom-script" "#!/bin/bash\necho custom"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
}

@test "entrypoint adds workspace bin to PATH" {
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    create_file "$TEST_WORKSPACE/.claude/bin/container-script" "#!/bin/bash\necho container"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
}

@test "entrypoint does not copy bin scripts from project" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/custom-script" "#!/bin/bash\necho custom"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    refute_output_contains "Found project-specific bin scripts"
    refute_output_contains "Project bin scripts copied"
    # File should NOT be copied to workspace bin
    assert_file_not_exists "$TEST_WORKSPACE/.claude/bin/custom-script"
}

@test "entrypoint handles missing bin directory gracefully" {
    # Don't create .claude/bin directory
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    refute_output_contains "Found project-specific bin scripts"
    refute_output_contains "Project bin scripts copied"
}
