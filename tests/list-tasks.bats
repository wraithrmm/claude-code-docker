#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Tests for list-tasks script

load test_helper

# Override setup to use standardized playground test setup
setup() {
    setup_playground_test
}


@test "list-tasks: shows empty message when no tasks exist" {
    copy_test_script "list-tasks"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "# Task List (All Tasks)"
    assert_output_contains "# Global Tasks"
    assert_output_contains "planning (0 tasks)"
    assert_output_contains "approved (0 tasks)"
    assert_output_contains "in-progress (0 tasks)"
    assert_output_contains "completed (0 tasks)"
    assert_output_contains "Total tasks: 0"
}

@test "list-tasks: shows tasks in planning status" {
    copy_test_script "list-tasks"
    create_task_file "planning" "implement-feature" "2024-01-15 10:00:00" "none"
    create_task_file "planning" "fix-bug" "2024-01-15 11:00:00" "none"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "## planning (2 tasks)"
    assert_output_contains "- implement-feature"
    assert_output_contains "Created: 2024-01-15 10:00:00"
    assert_output_contains "- fix-bug"
    assert_output_contains "Created: 2024-01-15 11:00:00"
}

@test "list-tasks: shows tasks in all statuses" {
    copy_test_script "list-tasks"
    create_task_file "planning" "plan-task"
    create_task_file "approved" "approved-task"
    create_task_file "in-progress" "current-task"
    create_task_file "completed" "done-task"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
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

@test "list-tasks: shows PRP template when specified" {
    copy_test_script "list-tasks"
    create_task_file "planning" "sql-task" "2024-01-15 10:00:00" "sql-to-entity-mapper"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "- sql-task"
    assert_output_contains "Template: sql-to-entity-mapper"
}

@test "list-tasks: does not show template line when template is none" {
    copy_test_script "list-tasks"
    create_task_file "planning" "no-template-task" "2024-01-15 10:00:00" "none"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "- no-template-task"
    refute_output_contains "Template: none"
}

@test "list-tasks: handles missing Created field gracefully" {
    copy_test_script "list-tasks"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/planning"
    # Create task without Created field
    cat > "$TEST_PROJECT/ai-playground/tasks/planning/broken-task.md" << EOF
# Task: broken-task
Status: planning
Updated: 2024-01-15 10:00:00
PRP-Template: none
EOF
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "- broken-task"
    assert_output_contains "Created: Unknown"
}

@test "list-tasks: handles empty status directories" {
    copy_test_script "list-tasks"
    # Create empty directories
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/planning"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/approved"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/in-progress"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/completed"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "## planning (0 tasks)"
    assert_output_contains "No tasks"
    assert_output_contains "## approved (0 tasks)"
    assert_output_contains "## in-progress (0 tasks)"
    assert_output_contains "## completed (0 tasks)"
    assert_output_contains "Total tasks: 0"
}

@test "list-tasks: ignores non-md files in task directories" {
    copy_test_script "list-tasks"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/planning"
    touch "$TEST_PROJECT/ai-playground/tasks/planning/not-a-task.txt"
    touch "$TEST_PROJECT/ai-playground/tasks/planning/.hidden"
    create_task_file "planning" "real-task"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "## planning (1 tasks)"
    assert_output_contains "- real-task"
    refute_output_contains "not-a-task"
    refute_output_contains ".hidden"
    assert_output_contains "Total tasks: 1"
}

@test "list-tasks: works when tasks directory doesn't exist" {
    copy_test_script "list-tasks"
    # Don't create any task directories
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "# Task List (All Tasks)"
    assert_output_contains "Total tasks: 0"
}

@test "list-tasks: counts multiple tasks correctly" {
    copy_test_script "list-tasks"
    create_task_file "planning" "task1"
    create_task_file "planning" "task2"
    create_task_file "approved" "task3"
    create_task_file "in-progress" "task4"
    create_task_file "in-progress" "task5"
    create_task_file "completed" "task6"
    create_task_file "completed" "task7"
    create_task_file "completed" "task8"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "## planning (2 tasks)"
    assert_output_contains "## approved (1 tasks)"
    assert_output_contains "## in-progress (2 tasks)"
    assert_output_contains "## completed (3 tasks)"
    assert_output_contains "Total tasks: 8"
}


@test "list-tasks: shows project tasks" {
    copy_test_script "list-tasks"
    
    # Create global tasks
    create_task_file "planning" "global-task1"
    create_task_file "approved" "global-task2"
    
    # Create project with tasks
    mkdir -p "$TEST_PROJECT/ai-playground/projects/test-project"
    create_project_task_file "test-project" "planning" "project-task1"
    create_project_task_file "test-project" "in-progress" "project-task2"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "# Global Tasks"
    assert_output_contains "- global-task1"
    assert_output_contains "- global-task2"
    assert_output_contains "# Project Tasks"
    assert_output_contains "## Project: test-project"
    assert_output_contains "- [test-project] project-task1"
    assert_output_contains "- [test-project] project-task2"
    assert_output_contains "Global tasks: 2"
    assert_output_contains "Project tasks: 2"
    assert_output_contains "Total tasks: 4"
}

@test "list-tasks: shows multiple projects" {
    copy_test_script "list-tasks"
    
    # Create tasks in different projects
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project-a"
    mkdir -p "$TEST_PROJECT/ai-playground/projects/project-b"
    create_project_task_file "project-a" "planning" "task-a1"
    create_project_task_file "project-a" "completed" "task-a2"
    create_project_task_file "project-b" "approved" "task-b1"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    assert_output_contains "## Project: project-a"
    assert_output_contains "- [project-a] task-a1"
    assert_output_contains "- [project-a] task-a2"
    assert_output_contains "## Project: project-b"
    assert_output_contains "- [project-b] task-b1"
    assert_output_contains "Project tasks: 3"
}

@test "list-tasks: handles projects without tasks directory" {
    copy_test_script "list-tasks"
    
    # Create project without tasks subdirectory
    mkdir -p "$TEST_PROJECT/ai-playground/projects/empty-project"
    touch "$TEST_PROJECT/ai-playground/projects/empty-project/plan.md"
    
    # Create another project with tasks
    mkdir -p "$TEST_PROJECT/ai-playground/projects/active-project"
    create_project_task_file "active-project" "planning" "task1"
    
    run "$TEST_WORKSPACE/.claude/bin/list-tasks"
    
    assert_success
    refute_output_contains "empty-project"
    assert_output_contains "## Project: active-project"
    assert_output_contains "- [active-project] task1"
}