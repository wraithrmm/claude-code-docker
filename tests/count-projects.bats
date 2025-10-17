#!/usr/bin/env bats

# Tests for count-projects script (renamed from ai-playground-count.sh)

load test_helper

# Override setup to use standardized bin test setup
setup() {
    setup_bin_test
}

@test "count-projects: returns 0 when no projects directory" {
    copy_test_script "count-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/count-projects"
    
    assert_success
    assert_output "0"
}

@test "count-projects: returns 0 when projects directory is empty" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects"
    
    copy_test_script "count-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/count-projects"
    
    assert_success
    assert_output "0"
}

@test "count-projects: returns correct project count" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project1"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project2"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project3"
    # Create a file (not a directory) - should not be counted
    touch "$TEST_PROJECT/ai-playground/projects/not-a-project.txt"
    
    copy_test_script "count-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/count-projects"
    
    assert_success
    assert_output "3"
}

@test "count-projects: ignores files in projects directory" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects"
    touch "$TEST_PROJECT/ai-playground/projects/file1.txt"
    touch "$TEST_PROJECT/ai-playground/projects/file2.md"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/real-project"
    
    copy_test_script "count-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/count-projects"
    
    assert_success
    assert_output "1"
}