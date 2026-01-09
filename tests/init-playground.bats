#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Tests for init-playground script (renamed from ai-playground-init.sh)

load test_helper

# Override setup to use standardized bin test setup
setup() {
    setup_bin_test
}

@test "init-playground: creates full directory structure when missing" {
    copy_test_script "init-playground"
    
    # Run init script
    run "$TEST_WORKSPACE/.claude/bin/init-playground"
    
    assert_success
    assert_output_contains "Following CLAUDE.md process"
    assert_output_contains "Creating ai-playground directory structure..."
    assert_output_contains "✅ ai-playground directory structure created"
    assert_dir_exists "$TEST_PROJECT/ai-playground"
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/planning"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/approved"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/in-progress"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/completed"
}

@test "init-playground: handles existing ai-playground directory" {
    # Create ai-playground directory first
    mkdir -p "$TEST_PROJECT/ai-playground"
    
    copy_test_script "init-playground"
    
    run "$TEST_WORKSPACE/.claude/bin/init-playground"
    
    assert_success
    assert_output_contains "✅ ai-playground directory exists"
    refute_output_contains "Creating ai-playground directory structure..."
    # Should still create subdirectories
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks"
}

@test "init-playground: lists existing projects with numbers" {
    # Create some test projects
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project-alpha"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project-beta"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project-gamma"
    
    copy_test_script "init-playground"
    
    run "$TEST_WORKSPACE/.claude/bin/init-playground"
    
    assert_success
    assert_output_contains "Existing projects:"
    assert_output_contains "1. 📁 project-alpha"
    assert_output_contains "2. 📁 project-beta"
    assert_output_contains "3. 📁 project-gamma"
    assert_output_contains "Found 3 project(s)"
}

@test "init-playground: counts tasks correctly" {
    # Create some test tasks
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/planning"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/approved"
    touch "$TEST_PROJECT/ai-playground/tasks/planning/task1.md"
    touch "$TEST_PROJECT/ai-playground/tasks/planning/task2.md"
    touch "$TEST_PROJECT/ai-playground/tasks/approved/task3.md"
    
    copy_test_script "init-playground"
    
    run "$TEST_WORKSPACE/.claude/bin/init-playground"
    
    assert_success
    assert_output_contains "Found 3 task(s)"
}

@test "init-playground: provides usage guidance" {
    copy_test_script "init-playground"
    
    run "$TEST_WORKSPACE/.claude/bin/init-playground"
    
    assert_success
    assert_output_contains "Ready for new work:"
    assert_output_contains "Use /list-projects to see projects or /list-tasks to see tasks"
}