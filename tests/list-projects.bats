#!/usr/bin/env bats

# Tests for list-projects script (renamed from ai-playground-list.sh)

load test_helper

# Override setup to use standardized bin test setup
setup() {
    setup_bin_test
}

@test "list-projects: handles missing projects directory" {
    copy_test_script "list-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/list-projects"
    
    assert_success
    assert_output_contains "No projects directory found"
    assert_output_contains "Run /init-playground to set up the ai-playground structure"
}

@test "list-projects: handles empty projects directory" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects"
    
    copy_test_script "list-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/list-projects"
    
    assert_success
    assert_output_contains "No projects found"
    assert_output_contains "Use /create-project <project-name> to create a new project"
}

@test "list-projects: shows numbered projects with status.json" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/test-project"
    
    # Create a status.json file
    cat > "$TEST_PROJECT/ai-playground/projects/test-project/status.json" << EOF
{
    "project": "test-project",
    "status": "active",
    "completion_percent": 75,
    "created": "2024-01-15 10:00:00",
    "last_updated": "2024-01-15 14:30:00",
    "summary": "Test project for unit tests"
}
EOF
    
    copy_test_script "list-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/list-projects"
    
    assert_success
    assert_output_contains "1. 📁 test-project"
    assert_output_contains "Status: active"
    assert_output_contains "Progress: 75%"
    assert_output_contains "Created: 2024-01-15 10:00:00"
    assert_output_contains "Last updated: 2024-01-15 14:30:00"
    assert_output_contains "Summary: Test project for unit tests"
    assert_output_contains "Total projects: 1"
}

@test "list-projects: handles missing status.json" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/no-status-project"
    
    copy_test_script "list-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/list-projects"
    
    assert_success
    assert_output_contains "1. 📁 no-status-project"
    assert_output_contains "⚠️  No status.json file"
}

@test "list-projects: maintains alphabetical order with numbering" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/zebra-project"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/alpha-project"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/middle-project"
    
    copy_test_script "list-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/list-projects"
    
    assert_success
    assert_output_contains "1. 📁 alpha-project"
    assert_output_contains "2. 📁 middle-project"
    assert_output_contains "3. 📁 zebra-project"
}

@test "list-projects: shows correct command hint" {
    mkdir -p "$TEST_PROJECT/ai-playground/projects/test-project"
    
    copy_test_script "list-projects"
    
    run "$TEST_WORKSPACE/.claude/bin/list-projects"
    
    assert_success
    assert_output_contains "Use '/continue-project <project-name>' or '/continue-project <number>' to resume a project"
}