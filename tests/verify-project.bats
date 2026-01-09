#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Tests for verify-project script (renamed from ai-playground-verify-project.sh)

load test_helper

# Override setup to use standardized bin test setup
setup() {
    setup_bin_test
}

@test "verify-project: requires project name" {
    copy_test_script "verify-project"
    
    run "$TEST_WORKSPACE/.claude/bin/verify-project"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name required"
    assert_output_contains "Usage: verify-project <project-name>"
}

@test "verify-project: checks all required files" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/complete-project"
    touch "$TEST_PROJECT/ai-playground/projects/complete-project/plan.md"
    touch "$TEST_PROJECT/ai-playground/projects/complete-project/progress.md"
    touch "$TEST_PROJECT/ai-playground/projects/complete-project/status.json"
    touch "$TEST_PROJECT/ai-playground/projects/complete-project/notes.md"
    
    copy_test_script "verify-project"
    
    run "$TEST_WORKSPACE/.claude/bin/verify-project" "complete-project"
    
    assert_success
    assert_output_contains "✅ plan.md exists"
    assert_output_contains "✅ progress.md exists"
    assert_output_contains "✅ status.json exists"
    assert_output_contains "✅ notes.md exists"
}

@test "verify-project: reports missing files" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/incomplete-project"
    touch "$TEST_PROJECT/ai-playground/projects/incomplete-project/plan.md"
    # Missing progress.md, status.json, notes.md
    
    copy_test_script "verify-project"
    
    run "$TEST_WORKSPACE/.claude/bin/verify-project" "incomplete-project"
    
    assert_success
    assert_output_contains "✅ plan.md exists"
    assert_output_contains "⚠️  Missing required files:"
    assert_output_contains "- progress.md"
    assert_output_contains "- status.json"
    assert_output_contains "- notes.md"
}

@test "verify-project: handles non-existent project" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects"
    
    copy_test_script "verify-project"
    
    run "$TEST_WORKSPACE/.claude/bin/verify-project" "non-existent"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project directory not found:"
}