#!/usr/bin/env bats

# Tests for create-project-task script

load test_helper

# Override setup to use standardized playground test setup
setup() {
    setup_playground_test
}

@test "create-project-task: requires project name" {
    copy_test_script "create-project-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name and task name are required"
    assert_output_contains "Usage: create-project-task <project-name> <task-name>"
}

@test "create-project-task: requires task name" {
    copy_test_script "create-project-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name and task name are required"
    assert_output_contains "Usage: create-project-task <project-name> <task-name>"
}

@test "create-project-task: fails if project does not exist" {
    copy_test_script "create-project-task"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "non-existent-project" "test-task"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project 'non-existent-project' does not exist"
    assert_output_contains "Use '/create-project non-existent-project' to create it first"
}

@test "create-project-task: creates task in existing project" {
    copy_test_script "create-project-task"
    create_test_project "test-project"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project" "implement-feature"
    
    assert_success
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/test-project/tasks/planning/implement-feature.md"
    assert_output_contains "✅ Task created successfully in project 'test-project'"
    assert_output_contains "Task file: $TEST_PROJECT/ai-playground/projects/test-project/tasks/planning/implement-feature.md"
}

@test "create-project-task: task file contains correct structure" {
    copy_test_script "create-project-task"
    create_test_project "test-project"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project" "test-structure"
    
    assert_success
    local task_file="$TEST_PROJECT/ai-playground/projects/test-project/tasks/planning/test-structure.md"
    assert_file_contains "$task_file" "# Task: test-structure"
    assert_file_contains "$task_file" "Status: planning"
    assert_file_contains "$task_file" "Created:"
    assert_file_contains "$task_file" "Updated:"
    assert_file_contains "$task_file" "PRP-Template: none"
    assert_file_contains "$task_file" "Project: test-project"
    assert_file_contains "$task_file" "## Project Intention"
    assert_file_contains "$task_file" "## Acceptance Criteria"
    assert_file_contains "$task_file" "## Implementation Approach"
    assert_file_contains "$task_file" "## Technical Details"
    assert_file_contains "$task_file" "## Notes"
}

@test "create-project-task: prevents duplicate task creation in same directory" {
    copy_test_script "create-project-task"
    create_test_project "test-project"
    
    # Create first task
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project" "duplicate-test"
    assert_success
    
    # Try to create same task again
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project" "duplicate-test"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Task 'duplicate-test' already exists in planning directory"
}

@test "create-project-task: prevents duplicate task creation across all status directories" {
    copy_test_script "create-project-task"
    create_test_project "test-project"
    
    # Create existing task in approved directory
    touch "$TEST_PROJECT/ai-playground/projects/test-project/tasks/approved/existing-task.md"
    
    # Try to create task with same name
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project" "existing-task"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Task 'existing-task' already exists in approved directory"
}

@test "create-project-task: provides helpful next steps" {
    copy_test_script "create-project-task"
    create_test_project "test-project"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project" "guidance-test"
    
    assert_success
    assert_output_contains "Next steps:"
    assert_output_contains "1. Edit the task file to add details and acceptance criteria"
    assert_output_contains "2. Reference appropriate PRP templates from /workspace/project/.claude/prp-templates/"
    assert_output_contains "3. When ready, move the task file to the approved directory to begin work"
}

@test "create-project-task: creates task directories if they don't exist" {
    copy_test_script "create-project-task"
    # Create project without task directories
    mkdir -p "$TEST_PROJECT/ai-playground/projects/minimal-project"
    echo "# Project: minimal-project" > "$TEST_PROJECT/ai-playground/projects/minimal-project/plan.md"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "minimal-project" "test-task"
    
    assert_success
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/minimal-project/tasks/planning"
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/minimal-project/tasks/approved"
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/minimal-project/tasks/in-progress"
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/minimal-project/tasks/completed"
}

@test "create-project-task: handles task names with hyphens" {
    copy_test_script "create-project-task"
    create_test_project "test-project"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "test-project" "implement-new-feature"
    
    assert_success
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/test-project/tasks/planning/implement-new-feature.md"
    assert_file_contains "$TEST_PROJECT/ai-playground/projects/test-project/tasks/planning/implement-new-feature.md" "# Task: implement-new-feature"
}

@test "create-project-task: handles project names with hyphens" {
    copy_test_script "create-project-task"
    create_test_project "my-awesome-project"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "my-awesome-project" "test-task"
    
    assert_success
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/my-awesome-project/tasks/planning/test-task.md"
}

@test "create-project-task: respects PLAYGROUND_DIR environment variable" {
    copy_test_script "create-project-task"
    
    # Set custom playground directory
    export CUSTOM_PLAYGROUND="$TEST_PROJECT/custom-playground"
    export PLAYGROUND_DIR="$CUSTOM_PLAYGROUND"
    
    # Create project in custom location
    mkdir -p "$CUSTOM_PLAYGROUND/projects/custom-project"
    echo "# Project: custom-project" > "$CUSTOM_PLAYGROUND/projects/custom-project/plan.md"
    
    run "$TEST_WORKSPACE/.claude/bin/create-project-task" "custom-project" "test-task"
    
    assert_success
    assert_file_exists "$CUSTOM_PLAYGROUND/projects/custom-project/tasks/planning/test-task.md"
}