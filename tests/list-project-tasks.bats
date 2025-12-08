#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Tests for list-project-tasks script

load test_helper

# Override setup to use standardized playground test setup
setup() {
    setup_playground_test
}

# Helper to create a project task file with metadata
create_project_task() {
    local project_name="$1"
    local status="$2"
    local task_name="$3"
    local created_date="${4:-2024-01-15 10:00:00}"
    local template="${5:-none}"
    
    mkdir -p "$TEST_PROJECT/ai-playground/projects/$project_name/tasks/$status"
    cat > "$TEST_PROJECT/ai-playground/projects/$project_name/tasks/$status/$task_name.md" << EOF
# Task: $task_name
Status: $status
Created: $created_date
Updated: $created_date
PRP-Template: $template

## Project Intention
Test task for $task_name in project $project_name
EOF
}

@test "list-project-tasks: requires project name" {
    copy_test_script "list-project-tasks"
    mkdir -p "$TEST_PROJECT/ai-playground"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name required"
    assert_output_contains "Usage: list-project-tasks <project-name>"
}

@test "list-project-tasks: fails when ai-playground not initialized" {
    # Use basic setup instead of playground setup for this test
    setup_bin_test
    copy_test_script "list-project-tasks"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "test-project"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: AI playground not initialized"
    assert_output_contains "Run '/init-playground' first"
}

@test "list-project-tasks: fails when project does not exist" {
    copy_test_script "list-project-tasks"
    mkdir -p "$TEST_PROJECT/ai-playground/projects"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "non-existent-project"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project 'non-existent-project' does not exist"
    assert_output_contains "Use '/list-projects' to see available projects"
}

@test "list-project-tasks: shows empty message when project has no tasks" {
    copy_test_script "list-project-tasks"
    create_test_project "empty-project"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "empty-project"
    
    assert_success
    assert_output_contains "# Task List for Project: empty-project"
    assert_output_contains "## planning (0 tasks)"
    assert_output_contains "No tasks"
    assert_output_contains "## approved (0 tasks)"
    assert_output_contains "## in-progress (0 tasks)"
    assert_output_contains "## completed (0 tasks)"
    assert_output_contains "Total tasks: 0"
}

@test "list-project-tasks: lists tasks in planning status" {
    copy_test_script "list-project-tasks"
    create_test_project "test-project"
    create_project_task "test-project" "planning" "design-api" "2024-01-15 10:00:00" "none"
    create_project_task "test-project" "planning" "create-models" "2024-01-15 11:00:00" "create-model"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "test-project"
    
    assert_success
    assert_output_contains "## planning (2 tasks)"
    assert_output_contains "- design-api"
    assert_output_contains "Created: 2024-01-15 10:00:00"
    assert_output_contains "- create-models"
    assert_output_contains "Created: 2024-01-15 11:00:00"
    assert_output_contains "Template: create-model"
}

@test "list-project-tasks: lists tasks in all statuses" {
    copy_test_script "list-project-tasks"
    create_test_project "full-project"
    create_project_task "full-project" "planning" "plan-task"
    create_project_task "full-project" "approved" "approved-task"
    create_project_task "full-project" "in-progress" "current-task"
    create_project_task "full-project" "completed" "done-task"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "full-project"
    
    assert_success
    assert_output_contains "## planning (1 tasks)"
    assert_output_contains "- plan-task"
    assert_output_contains "## approved (1 tasks)"
    assert_output_contains "- approved-task"
    assert_output_contains "## in-progress (1 tasks)"
    assert_output_contains "- current-task"
    assert_output_contains "## completed (1 tasks)"
    assert_output_contains "- done-task"
    assert_output_contains "Total tasks: 4"
}

@test "list-project-tasks: shows PRP template when specified" {
    copy_test_script "list-project-tasks"
    create_test_project "template-project"
    create_project_task "template-project" "planning" "api-task" "2024-01-15 10:00:00" "api-endpoint"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "template-project"
    
    assert_success
    assert_output_contains "- api-task"
    assert_output_contains "Template: api-endpoint"
}

@test "list-project-tasks: does not show template line when template is none" {
    copy_test_script "list-project-tasks"
    create_test_project "no-template-project"
    create_project_task "no-template-project" "planning" "simple-task" "2024-01-15 10:00:00" "none"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "no-template-project"
    
    assert_success
    assert_output_contains "- simple-task"
    refute_output_contains "Template: none"
}

@test "list-project-tasks: handles missing Created field gracefully" {
    copy_test_script "list-project-tasks"
    create_test_project "broken-project"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/broken-project/tasks/planning"
    # Create task without Created field
    cat > "$TEST_PROJECT/ai-playground/projects/broken-project/tasks/planning/broken-task.md" << EOF
# Task: broken-task
Status: planning
Updated: 2024-01-15 10:00:00
PRP-Template: none
EOF
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "broken-project"
    
    assert_success
    assert_output_contains "- broken-task"
    assert_output_contains "Created: Unknown"
}

@test "list-project-tasks: ignores non-md files in task directories" {
    copy_test_script "list-project-tasks"
    create_test_project "mixed-project"
    create_project_task "mixed-project" "planning" "real-task"
    touch "$TEST_PROJECT/ai-playground/projects/mixed-project/tasks/planning/not-a-task.txt"
    touch "$TEST_PROJECT/ai-playground/projects/mixed-project/tasks/planning/.hidden"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "mixed-project"
    
    assert_success
    assert_output_contains "## planning (1 tasks)"
    assert_output_contains "- real-task"
    refute_output_contains "not-a-task"
    refute_output_contains ".hidden"
    assert_output_contains "Total tasks: 1"
}

@test "list-project-tasks: counts multiple tasks correctly" {
    copy_test_script "list-project-tasks"
    create_test_project "big-project"
    create_project_task "big-project" "planning" "task1"
    create_project_task "big-project" "planning" "task2"
    create_project_task "big-project" "approved" "task3"
    create_project_task "big-project" "in-progress" "task4"
    create_project_task "big-project" "in-progress" "task5"
    create_project_task "big-project" "completed" "task6"
    create_project_task "big-project" "completed" "task7"
    create_project_task "big-project" "completed" "task8"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "big-project"
    
    assert_success
    assert_output_contains "## planning (2 tasks)"
    assert_output_contains "## approved (1 tasks)"
    assert_output_contains "## in-progress (2 tasks)"
    assert_output_contains "## completed (3 tasks)"
    assert_output_contains "Total tasks: 8"
}

@test "list-project-tasks: creates task directories if they don't exist" {
    copy_test_script "list-project-tasks"
    create_test_project "new-project"
    # Don't create task directories
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "new-project"
    
    assert_success
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/new-project/tasks/planning"
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/new-project/tasks/approved"
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/new-project/tasks/in-progress"
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/new-project/tasks/completed"
}

@test "list-project-tasks: works with project names containing spaces" {
    copy_test_script "list-project-tasks"
    create_test_project "my awesome project"
    create_project_task "my awesome project" "planning" "test-task"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "my awesome project"
    
    assert_success
    assert_output_contains "# Task List for Project: my awesome project"
    assert_output_contains "## planning (1 tasks)"
    assert_output_contains "- test-task"
}

@test "list-project-tasks: respects PLAYGROUND_DIR environment variable" {
    copy_test_script "list-project-tasks"
    # Set custom playground directory
    export PLAYGROUND_DIR="$TEST_PROJECT/custom-playground"
    mkdir -p "$PLAYGROUND_DIR/projects/env-project"
    create_file "$PLAYGROUND_DIR/projects/env-project/status.json" '{"project": "env-project", "status": "active"}'
    mkdir -p "$PLAYGROUND_DIR/projects/env-project/tasks/planning"
    
    run "$TEST_WORKSPACE/.claude/bin/list-project-tasks" "env-project"
    
    assert_success
    assert_output_contains "# Task List for Project: env-project"
}