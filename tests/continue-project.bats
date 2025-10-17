#!/usr/bin/env bats

# Tests for continue-project script (renamed from ai-playground-continue.sh)

load test_helper

# Override setup to use standardized playground test setup
setup() {
    setup_playground_test
}

@test "continue-project: requires project name or number" {
    copy_test_script "continue-project"
    
    run "$TEST_WORKSPACE/.claude/bin/continue-project"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name or number required"
    assert_output_contains "Usage: continue-project <project-name|number>"
}

@test "continue-project: works with project name" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/my-project"
    touch "$TEST_PROJECT/ai-playground/projects/my-project/plan.md"
    touch "$TEST_PROJECT/ai-playground/projects/my-project/progress.md"
    touch "$TEST_PROJECT/ai-playground/projects/my-project/status.json"
    touch "$TEST_PROJECT/ai-playground/projects/my-project/notes.md"
    
    # Copy both continue and verify scripts
    copy_test_script "continue-project"
    copy_test_script "verify-project"
    
    run "$TEST_WORKSPACE/.claude/bin/continue-project" "my-project"
    
    assert_success
    assert_output_contains "📋 Preparing to resume project: my-project"
    assert_output_contains "✅ plan.md exists"
    assert_output_contains "✅ progress.md exists"
    assert_output_contains "✅ status.json exists"
    assert_output_contains "✅ notes.md exists"
    assert_output_contains "✅ Project my-project is ready to continue"
}

@test "continue-project: works with project number" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/alpha-project"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/beta-project"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/gamma-project"
    
    # Create required files for beta-project
    touch "$TEST_PROJECT/ai-playground/projects/beta-project/plan.md"
    touch "$TEST_PROJECT/ai-playground/projects/beta-project/progress.md"
    touch "$TEST_PROJECT/ai-playground/projects/beta-project/status.json"
    touch "$TEST_PROJECT/ai-playground/projects/beta-project/notes.md"
    
    # Copy scripts
    copy_test_script "continue-project"
    copy_test_script "verify-project"
    
    # Continue project #2 (beta-project due to alphabetical order)
    run "$TEST_WORKSPACE/.claude/bin/continue-project" "2"
    
    assert_success
    assert_output_contains "📋 Preparing to resume project: beta-project"
}

@test "continue-project: handles invalid project number" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/test-project"
    
    copy_test_script "continue-project"
    
    run "$TEST_WORKSPACE/.claude/bin/continue-project" "5"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Invalid project number '5'"
    assert_output_contains "Valid range: 1-1"
}

@test "continue-project: handles non-existent project name" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/existing-project"
    
    copy_test_script "continue-project"
    
    run "$TEST_WORKSPACE/.claude/bin/continue-project" "non-existent"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project 'non-existent' not found"
    assert_output_contains "Available projects:"
    assert_output_contains "1. existing-project"
}

@test "continue-project: shows project file paths" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/show-paths"
    touch "$TEST_PROJECT/ai-playground/projects/show-paths/plan.md"
    touch "$TEST_PROJECT/ai-playground/projects/show-paths/progress.md"
    touch "$TEST_PROJECT/ai-playground/projects/show-paths/status.json"
    touch "$TEST_PROJECT/ai-playground/projects/show-paths/notes.md"
    
    copy_test_script "continue-project"
    copy_test_script "verify-project"
    
    run "$TEST_WORKSPACE/.claude/bin/continue-project" "show-paths"
    
    assert_success
    assert_output_contains "Project files ready for reading:"
    assert_output_contains "Read(\"$TEST_PROJECT/ai-playground/projects/show-paths/plan.md\")"
    assert_output_contains "Read(\"$TEST_PROJECT/ai-playground/projects/show-paths/progress.md\")"
    assert_output_contains "Read(\"$TEST_PROJECT/ai-playground/projects/show-paths/status.json\")"
    assert_output_contains "Read(\"$TEST_PROJECT/ai-playground/projects/show-paths/notes.md\")"
}