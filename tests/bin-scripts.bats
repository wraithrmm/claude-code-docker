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

# Test: Entrypoint integration tests for bin scripts

@test "entrypoint copies bin scripts from project" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/custom-script.sh" "#!/bin/bash\necho custom"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/custom-script.sh"
    assert_output_contains "Found project-specific bin scripts"
    assert_output_contains "Project bin scripts copied to container"
}

@test "entrypoint preserves bin script permissions" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/executable.sh" "#!/bin/bash\necho exec"
    make_executable "$TEST_PROJECT/.claude/bin/executable.sh"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_executable "$TEST_WORKSPACE/.claude/bin/executable.sh"
}

@test "entrypoint does not overwrite existing bin scripts" {
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    create_file "$TEST_WORKSPACE/.claude/bin/existing.sh" "original content"
    
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/existing.sh" "new content"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_contains "$TEST_WORKSPACE/.claude/bin/existing.sh" "original content"
    refute_file_contains "$TEST_WORKSPACE/.claude/bin/existing.sh" "new content"
}

@test "entrypoint handles missing bin directory gracefully" {
    # Don't create .claude/bin directory
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Found project-specific bin scripts"
    refute_output_contains "Project bin scripts copied"
}