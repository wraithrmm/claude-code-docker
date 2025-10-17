#!/usr/bin/env bats

# Tests for create-task script

load test_helper
load test_helper_ai_playground
load test_helper_output

# Override setup to use AI playground setup
setup() {
    setup_ai_playground
}

@test "create-task: requires task name" {
    copy_test_script "create-task"
    
    assert_script_requires_args "$TEST_WORKSPACE/.claude/bin/create-task" \
        "Error: Task name is required" \
        "Usage: create-task <task-name>"
}

@test "create-task: creates task directory structure on first run" {
    copy_test_script "create-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-task" "test-task"
    
    assert_success
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/planning"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/approved"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/in-progress"
    assert_dir_exists "$TEST_PROJECT/ai-playground/tasks/completed"
}

@test "create-task: creates task file in planning directory" {
    copy_test_script "create-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-task" "implement-feature"
    
    assert_success
    assert_file_exists "$TEST_PROJECT/ai-playground/tasks/planning/implement-feature.md"
    assert_output_contains "Task created successfully: $TEST_PROJECT/ai-playground/tasks/planning/implement-feature.md"
}

@test "create-task: task file contains correct structure" {
    copy_test_script "create-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-task" "test-structure"
    
    assert_success
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "# Task: test-structure"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "Status: planning"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "Created:"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "Updated:"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "PRP-Template: none"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "## Project Intention"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "## Acceptance Criteria"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "## Implementation Approach"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "## Technical Details"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/test-structure.md" "## Notes"
}

@test "create-task: prevents duplicate task creation in same directory" {
    copy_test_script "create-task"
    
    # Create first task
    run "$TEST_WORKSPACE/.claude/bin/create-task" "duplicate-test"
    assert_success
    
    # Try to create same task again
    run "$TEST_WORKSPACE/.claude/bin/create-task" "duplicate-test"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Task 'duplicate-test' already exists in planning directory"
}

@test "create-task: prevents duplicate task creation across all directories" {
    copy_test_script "create-task"
    
    # Create task structure first
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/approved"
    # Create existing task in approved directory
    touch "$TEST_PROJECT/ai-playground/tasks/approved/existing-task.md"
    
    # Try to create task with same name
    run "$TEST_WORKSPACE/.claude/bin/create-task" "existing-task"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Task 'existing-task' already exists in approved directory"
}

@test "create-task: provides next steps guidance" {
    copy_test_script "create-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-task" "guidance-test"
    
    assert_success
    assert_output_contains "Next steps:"
    assert_output_contains "1. Edit the task file to add details"
    assert_output_contains "2. When ready, use 'move-task guidance-test approved' to approve the task"
}

@test "create-task: handles task names with spaces" {
    copy_test_script "create-task"
    
    # The script receives multiple arguments when spaces are used
    # It will create a task with just the first word
    run "$TEST_WORKSPACE/.claude/bin/create-task" task with spaces
    
    assert_success
    assert_file_exists "$TEST_PROJECT/ai-playground/tasks/planning/task.md"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/task.md" "# Task: task"
}

@test "create-task: handles task names with special characters" {
    copy_test_script "create-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-task" "task-with-dashes"
    
    assert_success
    assert_file_exists "$TEST_PROJECT/ai-playground/tasks/planning/task-with-dashes.md"
    assert_file_contains "$TEST_PROJECT/ai-playground/tasks/planning/task-with-dashes.md" "# Task: task-with-dashes"
}