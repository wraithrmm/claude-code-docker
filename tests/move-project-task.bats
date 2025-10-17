#!/usr/bin/env bats

# Tests for move-project-task script

load test_helper

# Override setup to use standardized playground test setup
setup() {
    setup_playground_test
}

@test "move-project-task: requires all three arguments" {
    copy_test_script "move-project-task"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name, task name, and target status are required"
    assert_output_contains "Usage: move-project-task <project-name> <task-name> <status>"
}

@test "move-project-task: requires task name and status when project provided" {
    copy_test_script "move-project-task"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "my-project"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name, task name, and target status are required"
}

@test "move-project-task: requires status when project and task provided" {
    copy_test_script "move-project-task"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "my-project" "my-task"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project name, task name, and target status are required"
}

@test "move-project-task: checks for ai-playground initialization" {
    # Use basic setup instead of playground setup for this test
    setup_bin_test
    copy_test_script "move-project-task"
    # Don't create ai-playground directory
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "project" "task" "approved"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: AI playground not initialized"
    assert_output_contains "Run '/init-playground' first"
}

@test "move-project-task: validates project exists" {
    copy_test_script "move-project-task"
    mkdir -p "$TEST_PROJECT/ai-playground/projects"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "non-existent-project" "task" "approved"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Project 'non-existent-project' does not exist"
    assert_output_contains "Use '/list-projects' to see available projects"
}

@test "move-project-task: validates target status" {
    copy_test_script "move-project-task"
    create_test_project "test-project"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "test-project" "task-name" "invalid-status"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Invalid status 'invalid-status'"
    assert_output_contains "Valid statuses: planning, approved, in-progress, completed"
}

@test "move-project-task: reports task not found in project" {
    copy_test_script "move-project-task"
    create_test_project "test-project"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "test-project" "non-existent-task" "approved"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: Task 'non-existent-task' not found in project 'test-project'"
    assert_output_contains "Use '/list-project-tasks test-project' to see available tasks"
}

@test "move-project-task: moves task from planning to approved" {
    copy_test_script "move-project-task"
    create_test_project "test-project"
    create_project_task_file "test-project" "planning" "test-task"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "test-project" "test-task" "approved"
    
    assert_success
    assert_output_contains "Task 'test-task' moved from planning to approved in project 'test-project'"
    assert_file_not_exists "$TEST_PROJECT/ai-playground/projects/test-project/tasks/planning/test-task.md"
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/test-project/tasks/approved/test-task.md"
}

@test "move-project-task: updates status field in moved file" {
    copy_test_script "move-project-task"
    create_test_project "status-project"
    create_project_task_file "status-project" "planning" "status-test"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "status-project" "status-test" "in-progress"
    
    assert_success
    assert_file_contains "$TEST_PROJECT/ai-playground/projects/status-project/tasks/in-progress/status-test.md" "Status: in-progress"
    refute_file_contains "$TEST_PROJECT/ai-playground/projects/status-project/tasks/in-progress/status-test.md" "Status: planning"
}

@test "move-project-task: updates timestamp when moving" {
    copy_test_script "move-project-task"
    create_test_project "timestamp-project"
    create_project_task_file "timestamp-project" "approved" "timestamp-test" "2024-01-01 00:00:00"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "timestamp-project" "timestamp-test" "in-progress"
    
    assert_success
    # Check that Updated field has changed (won't match original date)
    refute_file_contains "$TEST_PROJECT/ai-playground/projects/timestamp-project/tasks/in-progress/timestamp-test.md" "Updated: 2024-01-01 00:00:00"
    assert_file_contains "$TEST_PROJECT/ai-playground/projects/timestamp-project/tasks/in-progress/timestamp-test.md" "Updated: "
}

@test "move-project-task: handles task already in target status" {
    copy_test_script "move-project-task"
    create_test_project "already-project"
    create_project_task_file "already-project" "approved" "already-there"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "already-project" "already-there" "approved"
    
    assert_success
    assert_output_contains "Task 'already-there' is already in approved"
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/already-project/tasks/approved/already-there.md"
}

@test "move-project-task: finds task across all status directories" {
    copy_test_script "move-project-task"
    create_test_project "find-project"
    create_project_task_file "find-project" "completed" "find-me"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "find-project" "find-me" "planning"
    
    assert_success
    assert_output_contains "Task 'find-me' moved from completed to planning in project 'find-project'"
    assert_file_not_exists "$TEST_PROJECT/ai-playground/projects/find-project/tasks/completed/find-me.md"
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/find-project/tasks/planning/find-me.md"
}

@test "move-project-task: provides next steps for approved status" {
    copy_test_script "move-project-task"
    create_test_project "guide-project"
    create_project_task_file "guide-project" "planning" "guide-approved"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "guide-project" "guide-approved" "approved"
    
    assert_success
    assert_output_contains "Task is now approved and ready to be worked on"
    assert_output_contains "Use 'move-project-task guide-project guide-approved in-progress' when you start working on it"
}

@test "move-project-task: provides next steps for in-progress status" {
    copy_test_script "move-project-task"
    create_test_project "progress-project"
    create_project_task_file "progress-project" "approved" "guide-progress"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "progress-project" "guide-progress" "in-progress"
    
    assert_success
    assert_output_contains "Task is now in progress"
    assert_output_contains "Use 'move-project-task progress-project guide-progress completed' when finished"
}

@test "move-project-task: provides celebration for completed status" {
    copy_test_script "move-project-task"
    create_test_project "complete-project"
    create_project_task_file "complete-project" "in-progress" "guide-complete"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "complete-project" "guide-complete" "completed"
    
    assert_success
    assert_output_contains "Task completed! 🎉"
}

@test "move-project-task: creates target directory if it doesn't exist" {
    copy_test_script "move-project-task"
    create_test_project "dir-project"
    create_project_task_file "dir-project" "planning" "create-dir-test"
    # Remove the target directory
    rm -rf "$TEST_PROJECT/ai-playground/projects/dir-project/tasks/approved"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "dir-project" "create-dir-test" "approved"
    
    assert_success
    assert_dir_exists "$TEST_PROJECT/ai-playground/projects/dir-project/tasks/approved"
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/dir-project/tasks/approved/create-dir-test.md"
}

@test "move-project-task: preserves file content except status and updated fields" {
    copy_test_script "move-project-task"
    create_test_project "content-project"
    create_project_task_file "content-project" "planning" "content-test"
    # Add some custom content
    echo "Custom content here" >> "$TEST_PROJECT/ai-playground/projects/content-project/tasks/planning/content-test.md"
    echo "More custom lines" >> "$TEST_PROJECT/ai-playground/projects/content-project/tasks/planning/content-test.md"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "content-project" "content-test" "approved"
    
    assert_success
    assert_file_contains "$TEST_PROJECT/ai-playground/projects/content-project/tasks/approved/content-test.md" "# Task: content-test"
    assert_file_contains "$TEST_PROJECT/ai-playground/projects/content-project/tasks/approved/content-test.md" "## Project Intention"
    assert_file_contains "$TEST_PROJECT/ai-playground/projects/content-project/tasks/approved/content-test.md" "Custom content here"
    assert_file_contains "$TEST_PROJECT/ai-playground/projects/content-project/tasks/approved/content-test.md" "More custom lines"
}

@test "move-project-task: handles multiple projects with same task names" {
    copy_test_script "move-project-task"
    create_test_project "project-a"
    create_test_project "project-b"
    create_project_task_file "project-a" "planning" "same-task"
    create_project_task_file "project-b" "approved" "same-task"
    
    run "$TEST_WORKSPACE/.claude/bin/move-project-task" "project-a" "same-task" "completed"
    
    assert_success
    assert_output_contains "Task 'same-task' moved from planning to completed in project 'project-a'"
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/project-a/tasks/completed/same-task.md"
    # Ensure project-b's task is untouched
    assert_file_exists "$TEST_PROJECT/ai-playground/projects/project-b/tasks/approved/same-task.md"
}