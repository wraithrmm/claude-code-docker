# PRP Template: Create New Claude Command

## Purpose
Create a new command for Claude Code, including the script, command documentation, tests, and all necessary configurations.

## Required Information Before Starting
- [ ] Command name (e.g., `list-tasks`, `create-project`)
- [ ] Command purpose and description
- [ ] Command parameters/arguments
- [ ] Expected output format
- [ ] Dependencies on other scripts or tools
- [ ] Error conditions to handle

## Implementation Steps

### 1. Create the Script
Create script in `/workspace/project/assets/.claude/bin/[command-name]` (no .sh extension)

**Script Structure**:
```bash
#!/bin/bash
# [Brief description of what the script does]

# Define base directories
PLAYGROUND_DIR="/workspace/project/ai-playground"
PROJECTS_DIR="$PLAYGROUND_DIR/projects"
TASKS_DIR="$PLAYGROUND_DIR/tasks"

# Check for required arguments
if [ -z "$1" ]; then
    echo "Error: [Parameter] required"
    echo "Usage: [command-name] <parameter>"
    exit 1
fi

# Main logic here

# Exit codes:
# 0 - Success
# 1 - Error (missing args, invalid input, etc.)
```

**Script Guidelines**:
- Use consistent error messaging format
- Include usage instructions on error
- Use proper exit codes
- Make paths configurable for testing
- Check for directory/file existence before operations
- Provide helpful output messages

### 2. Make Script Executable
```bash
chmod +x /workspace/project/assets/.claude/bin/[command-name]
```

### 3. Create Command Documentation
Create `/workspace/project/assets/.claude/commands/[command-name].md`

**Documentation Template**:
```markdown
# /[command-name]

[Brief description of the command]

## Usage
```
/[command-name] <required-param> [optional-param]
```

## Description
[Detailed description of what the command does and when to use it]

## Parameters
- `<required-param>`: [Description of required parameter]
- `[optional-param]`: [Description of optional parameter]

## Examples
```bash
/[command-name] example-value
```

## Output
[Description of what the command outputs]

## Error Handling
- [Error condition 1]: [What happens]
- [Error condition 2]: [What happens]

## Related Commands
- `/[related-command-1]` - [How it relates]
- `/[related-command-2]` - [How it relates]
```

### 4. Update Permissions in settings.json
Add to `/workspace/project/assets/.claude/settings.json`:
```json
"Bash(/workspace/.claude/bin/[command-name]:*)"
```

### 5. Create Tests
Create `/workspace/project/tests/[command-name].bats`

**Test Template**:
```bash
#!/usr/bin/env bats

# Tests for [command-name] script

load test_helper

# Override setup to also create bin directories
setup() {
    create_test_workspace
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    # Update the scripts to use test paths
    export PLAYGROUND_DIR="$TEST_PROJECT/ai-playground"
}

# Helper to copy and modify script for test environment
copy_test_script() {
    local script_name="$1"
    sed -e "s|/workspace/project/ai-playground|$TEST_PROJECT/ai-playground|g" \
        -e "s|/workspace/.claude/bin/|$TEST_WORKSPACE/.claude/bin/|g" \
        "$BATS_TEST_DIRNAME/../assets/.claude/bin/$script_name" > "$TEST_WORKSPACE/.claude/bin/$script_name"
    chmod +x "$TEST_WORKSPACE/.claude/bin/$script_name"
}

@test "[command-name]: requires [parameter]" {
    copy_test_script "[command-name]"
    
    run "$TEST_WORKSPACE/.claude/bin/[command-name]"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "Error: [Parameter] required"
    assert_output_contains "Usage: [command-name]"
}

@test "[command-name]: [test description]" {
    copy_test_script "[command-name]"
    
    # Set up test conditions
    
    run "$TEST_WORKSPACE/.claude/bin/[command-name]" "test-value"
    
    assert_success
    assert_output_contains "[expected output]"
}

# Add more tests for:
# - Success cases
# - Error conditions
# - Edge cases
# - Output format validation
```

### 6. Update Documentation

#### Update CLAUDE.md
Add the command to the appropriate section in `/workspace/project/assets/CLAUDE.md`:
- Project Commands section for project-related commands
- Task Commands section for task-related commands

#### Update README.md
Add to `/workspace/project/assets/.claude/bin/README.md` under the appropriate section

### 7. Integration Testing
- Test the script works correctly when called directly
- Test it works through Claude's command system
- Verify error messages are helpful
- Check that paths work correctly in Docker environment

## Acceptance Criteria
- [ ] Script created and executable
- [ ] Command documentation complete
- [ ] Tests written and passing
- [ ] Permissions added to settings.json
- [ ] CLAUDE.md updated with new command
- [ ] README.md in bin directory updated
- [ ] Script handles all error conditions gracefully
- [ ] Output format is consistent with other commands
- [ ] Script works in both test and production environments

## Common Patterns to Follow

### Error Message Format
```bash
echo "Error: [Specific error description]"
echo "Usage: [command-name] <parameter>"
exit 1
```

### Success Message Format
```bash
echo "✅ [Action completed successfully]"
echo ""
echo "Next steps:"
echo "1. [First next step]"
echo "2. [Second next step]"
```

### Directory Creation
```bash
mkdir -p "$DIRECTORY_PATH"
```

### File Existence Checks
```bash
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi
```

### Listing with Numbers
```bash
for i in "${!items[@]}"; do
    item_name="${items[$i]}"
    item_num=$((i+1))
    echo "$item_num. $item_name"
done
```

## Testing Checklist
- [ ] Test with no arguments
- [ ] Test with valid arguments
- [ ] Test with invalid arguments
- [ ] Test when directories don't exist
- [ ] Test when directories are empty
- [ ] Test with special characters in names
- [ ] Test output formatting
- [ ] Test in Docker environment

## Notes
- Keep scripts simple and focused on one task
- Use existing scripts as reference for patterns
- Ensure all paths can be overridden for testing
- Follow bash best practices (set -e for error handling, quote variables, etc.)
- Document any assumptions or limitations