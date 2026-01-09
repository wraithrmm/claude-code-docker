#!/bin/bash

# AI Playground specific test helper functions

# Standard setup for AI playground tests
setup_ai_playground() {
    create_test_workspace
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    export PLAYGROUND_DIR="$TEST_PROJECT/ai-playground"
}

# Standard setup for bin script tests
setup_bin_test() {
    create_test_workspace
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    export PLAYGROUND_DIR="$TEST_PROJECT/ai-playground"
}

# Setup with AI playground initialization
setup_playground_test() {
    setup_ai_playground
    create_ai_playground_structure
}

# Copy and modify scripts for test environment
copy_test_script() {
    local script_name="$1"
    sed -e "s|/workspace/project/ai-playground|$TEST_PROJECT/ai-playground|g" \
        -e "s|/workspace/.claude/bin/|$TEST_WORKSPACE/.claude/bin/|g" \
        "$BATS_TEST_DIRNAME/../assets/.claude/bin/$script_name" > "$TEST_WORKSPACE/.claude/bin/$script_name"
    chmod +x "$TEST_WORKSPACE/.claude/bin/$script_name"
}

# Create a task file with proper structure
create_task_file() {
    local status="$1"
    local task_name="$2"
    local created_date="${3:-2024-01-15 10:00:00}"
    local template="${4:-none}"
    
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/$status"
    cat > "$TEST_PROJECT/ai-playground/tasks/$status/$task_name.md" << EOF
# Task: $task_name
Status: $status
Created: $created_date
Updated: $created_date
PRP-Template: $template

## Project Intention
Test task for $task_name

## Acceptance Criteria
- [ ] Test criterion 1
- [ ] Test criterion 2

## Implementation Approach
Test implementation approach

## File Map
### New Files 🆕
- \`test/file.ext\` - Test file

### Modified Files ✏️
- \`test/existing.ext\` - Test modifications

## Technical Details
Test technical details

## Notes
Test notes
EOF
}

# Create a complete test project
create_test_project() {
    local project_name="$1"
    local status="${2:-active}"
    local project_dir="$TEST_PROJECT/ai-playground/projects/$project_name"
    
    mkdir -p "$project_dir"
    mkdir -p "$project_dir/tasks/planning"
    mkdir -p "$project_dir/tasks/approved"
    mkdir -p "$project_dir/tasks/in-progress"
    mkdir -p "$project_dir/tasks/completed"
    
    echo "# Project: $project_name" > "$project_dir/plan.md"
    echo "# Progress Log" > "$project_dir/progress.md"
    echo "# Project Notes" > "$project_dir/notes.md"
    
    cat > "$project_dir/status.json" << EOF
{
  "project": "$project_name",
  "created": "$(date '+%Y-%m-%d %H:%M:%S')",
  "status": "$status",
  "completion_percent": 0,
  "last_updated": "$(date '+%Y-%m-%d %H:%M:%S')",
  "summary": "Test project"
}
EOF
}

# Create a project-specific task file
create_project_task_file() {
    local project_name="$1"
    local status="$2"
    local task_name="$3"
    local created_date="${4:-2024-01-15 10:00:00}"
    
    mkdir -p "$TEST_PROJECT/ai-playground/projects/$project_name/tasks/$status"
    cat > "$TEST_PROJECT/ai-playground/projects/$project_name/tasks/$status/$task_name.md" << EOF
# Task: $task_name
Status: $status
Created: $created_date
Updated: $created_date
PRP-Template: none

## Project Intention
Test task for $task_name in project $project_name

## Acceptance Criteria
- [ ] Test criterion 1
- [ ] Test criterion 2

## Implementation Approach
Test implementation approach

## File Map
### New Files 🆕
- \`test/file.ext\` - Test file

### Modified Files ✏️
- \`test/existing.ext\` - Test modifications

## Technical Details
Test technical details

## Notes
Test notes
EOF
}

# Common pattern for argument validation tests
assert_script_requires_args() {
    local script_path="$1"
    local expected_error="$2"
    local expected_usage="${3:-}"
    
    run "$script_path"
    assert_failure
    assert_output_contains "$expected_error"
    
    if [[ -n "$expected_usage" ]]; then
        assert_output_contains "$expected_usage"
    fi
}

# Verify project directory structure
assert_creates_project_structure() {
    local project_name="$1"
    local project_dir="$TEST_PROJECT/ai-playground/projects/$project_name"
    
    assert_dir_exists "$project_dir"
    assert_dir_exists "$project_dir/tasks/planning"
    assert_dir_exists "$project_dir/tasks/approved"
    assert_dir_exists "$project_dir/tasks/in-progress"
    assert_dir_exists "$project_dir/tasks/completed"
    assert_file_exists "$project_dir/plan.md"
    assert_file_exists "$project_dir/progress.md"
    assert_file_exists "$project_dir/notes.md"
    assert_file_exists "$project_dir/status.json"
}

# Test duplicate prevention logic
assert_prevents_duplicate() {
    local script_path="$1"
    local args="$2"
    local expected_error="$3"
    
    run "$script_path" $args
    assert_failure
    assert_output_contains "$expected_error"
}

# Initialize AI playground directory structure
create_ai_playground_structure() {
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/planning"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/approved"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/in-progress"
    mkdir -p "$TEST_PROJECT/ai-playground/tasks/completed"
    mkdir -p "$TEST_PROJECT/ai-playground/projects"
}