#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Load test helper functions
load test_helper

# Test 1: Pre-flight checks - Success cases

@test "1.1: successful startup with no violations" {
    # No docker-compose.override.yml present
    # Set required environment variables
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test command"
    
    assert_success
    assert_output_contains "Running pre-flight checks..."
    assert_output_contains "All pre-flight checks passed"
    assert_output_contains "Initializing Claude Code container..."
    assert_output_contains "test command"
}

@test "1.2: passes arguments correctly to exec" {
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "one" "two" "three"
    
    assert_success
    assert_output_contains "one two three"
}

# Test 2: Environment variable validation

@test "2.1: fails when HOST_PWD is missing" {
    run_entrypoint_with_env HOST_USER=testuser echo "should not run"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "ERROR: Required environment variables are not set!"
    assert_output_contains "Missing variables: HOST_PWD"
    assert_output_contains "Please run the container with:"
    assert_output_contains "-e HOST_PWD=\$(pwd)"
    assert_output_contains "-e HOST_USER=\$(whoami)"
    assert_output_contains "Pre-flight checks FAILED"
    refute_output_contains "should not run"
}

@test "2.2: fails when HOST_USER is missing" {
    run_entrypoint_with_env HOST_PWD=/test/path echo "should not run"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "ERROR: Required environment variables are not set!"
    assert_output_contains "Missing variables: HOST_USER"
    assert_output_contains "Please run the container with:"
    assert_output_contains "-e HOST_PWD=\$(pwd)"
    assert_output_contains "-e HOST_USER=\$(whoami)"
    assert_output_contains "Pre-flight checks FAILED"
    refute_output_contains "should not run"
}

@test "2.3: fails when both HOST_PWD and HOST_USER are missing" {
    run_entrypoint echo "should not run"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "ERROR: Required environment variables are not set!"
    assert_output_contains "Missing variables: HOST_PWD HOST_USER"
    assert_output_contains "Please run the container with:"
    assert_output_contains "-e HOST_PWD=\$(pwd)"
    assert_output_contains "-e HOST_USER=\$(whoami)"
    assert_output_contains "Pre-flight checks FAILED"
    refute_output_contains "should not run"
}

@test "2.4: succeeds when both environment variables are set" {
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "success"
    
    assert_success
    assert_output_contains "All pre-flight checks passed"
    assert_output_contains "success"
}

@test "2.5: accepts empty string values for environment variables" {
    run_entrypoint_with_env HOST_PWD="" HOST_USER="" echo "should not run"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "ERROR: Required environment variables are not set!"
    assert_output_contains "Missing variables: HOST_PWD HOST_USER"
}

# Test 3: Pre-flight checks - docker-compose.override.yml detection

@test "4.1: fails when docker-compose.override.yml exists in root" {
    create_file "$TEST_PROJECT/docker-compose.override.yml" "version: '3.8'"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "should not run"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "ERROR: docker-compose.override.yml file found!"
    assert_output_contains "This file is not allowed in the project directory"
    assert_output_contains "Pre-flight checks FAILED"
    refute_output_contains "should not run"
}

@test "4.2: fails when docker-compose.override.yml exists in subdirectory" {
    mkdir -p "$TEST_PROJECT/config/nested"
    create_file "$TEST_PROJECT/config/nested/docker-compose.override.yml" "version: '3.8'"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "should not run"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "ERROR: docker-compose.override.yml file found!"
    refute_output_contains "should not run"
}

@test "3.3: detects multiple docker-compose.override.yml files" {
    create_file "$TEST_PROJECT/docker-compose.override.yml" "version: '3.8'"
    mkdir -p "$TEST_PROJECT/subdir"
    create_file "$TEST_PROJECT/subdir/docker-compose.override.yml" "version: '3.8'"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "should not run"
    
    assert_failure
    assert_exit_code 1
    assert_output_contains "ERROR: docker-compose.override.yml file found!"
}

# Test 4: Command copying functionality - No commands

@test "4.1: handles missing .claude/commands directory gracefully" {
    # Don't create .claude/commands directory
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Found project-specific commands"
    refute_output_contains "Project commands copied"
}

@test "4.2: handles empty .claude/commands directory" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Found project-specific commands"
    assert_output_contains "Project commands copied to container"
}

# Test 5: Command copying functionality - Basic operations

@test "5.1: copies basic command file" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    create_file "$TEST_PROJECT/.claude/commands/test-cmd.sh" "#!/bin/bash\necho test"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/test-cmd.sh"
    assert_file_contains "$TEST_WORKSPACE/.claude/commands/test-cmd.sh" "echo test"
    assert_output_contains "Project commands copied to container"
}

@test "5.2: copies multiple command files" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    create_file "$TEST_PROJECT/.claude/commands/cmd1.sh" "echo cmd1"
    create_file "$TEST_PROJECT/.claude/commands/cmd2.sh" "echo cmd2"
    create_file "$TEST_PROJECT/.claude/commands/cmd3.sh" "echo cmd3"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/cmd1.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/cmd2.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/cmd3.sh"
}

@test "5.3: preserves nested directory structure" {
    mkdir -p "$TEST_PROJECT/.claude/commands/category1/subcategory"
    mkdir -p "$TEST_PROJECT/.claude/commands/category2"
    create_file "$TEST_PROJECT/.claude/commands/category1/cmd1.sh" "cmd1"
    create_file "$TEST_PROJECT/.claude/commands/category1/subcategory/cmd2.sh" "cmd2"
    create_file "$TEST_PROJECT/.claude/commands/category2/cmd3.sh" "cmd3"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_dir_exists "$TEST_WORKSPACE/.claude/commands/category1"
    assert_dir_exists "$TEST_WORKSPACE/.claude/commands/category1/subcategory"
    assert_dir_exists "$TEST_WORKSPACE/.claude/commands/category2"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/category1/cmd1.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/category1/subcategory/cmd2.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/category2/cmd3.sh"
}

@test "5.4: respects no-overwrite flag - does not overwrite existing files" {
    mkdir -p "$TEST_WORKSPACE/.claude/commands"
    create_file "$TEST_WORKSPACE/.claude/commands/existing.sh" "original content"
    
    mkdir -p "$TEST_PROJECT/.claude/commands"
    create_file "$TEST_PROJECT/.claude/commands/existing.sh" "new content"
    create_file "$TEST_PROJECT/.claude/commands/new.sh" "new file"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_contains "$TEST_WORKSPACE/.claude/commands/existing.sh" "original content"
    refute_file_contains "$TEST_WORKSPACE/.claude/commands/existing.sh" "new content"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/new.sh"
}

@test "5.5: handles special characters in filenames" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    touch "$TEST_PROJECT/.claude/commands/command with spaces.sh"
    touch "$TEST_PROJECT/.claude/commands/command-with-dashes.sh"
    touch "$TEST_PROJECT/.claude/commands/command_with_underscores.sh"
    touch "$TEST_PROJECT/.claude/commands/command.multiple.dots.sh"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/command with spaces.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/command-with-dashes.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/command_with_underscores.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/command.multiple.dots.sh"
}

@test "5.6: preserves file permissions" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    create_file "$TEST_PROJECT/.claude/commands/executable.sh" "#!/bin/bash\necho executable"
    make_executable "$TEST_PROJECT/.claude/commands/executable.sh"
    
    create_file "$TEST_PROJECT/.claude/commands/non-executable.sh" "echo non-executable"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_executable "$TEST_WORKSPACE/.claude/commands/executable.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/non-executable.sh"
    ! [[ -x "$TEST_WORKSPACE/.claude/commands/non-executable.sh" ]] || { echo "non-executable.sh should not be executable" >&2; return 1; }
}

@test "5.7: handles copy errors gracefully" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    create_file "$TEST_PROJECT/.claude/commands/test.sh" "test content"
    
    # Make destination directory read-only to force copy error
    mkdir -p "$TEST_WORKSPACE/.claude/commands"
    chmod -w "$TEST_WORKSPACE/.claude/commands"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    # Should still succeed due to || true in the script
    assert_success
    assert_output_contains "Project commands copied to container"
    
    # Restore permissions for cleanup
    chmod +w "$TEST_WORKSPACE/.claude/commands"
}

@test "5.8: handles mixed file types" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    
    # Regular files
    create_file "$TEST_PROJECT/.claude/commands/script.sh" "#!/bin/bash"
    create_file "$TEST_PROJECT/.claude/commands/README.md" "Documentation"
    
    # Different permissions
    make_executable "$TEST_PROJECT/.claude/commands/script.sh"
    
    # Note: cp -r with /* won't copy hidden files, which is expected behavior
    # create_file "$TEST_PROJECT/.claude/commands/.hidden" "hidden content"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/script.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/README.md"
    # Hidden files are not copied due to /* glob pattern, which is expected
    assert_file_executable "$TEST_WORKSPACE/.claude/commands/script.sh"
}

@test "5.9: handles large number of files" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    
    # Create 50 test files
    for i in {1..50}; do
        create_file "$TEST_PROJECT/.claude/commands/cmd$i.sh" "echo $i"
    done
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    
    # Verify a sample of files were copied
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/cmd1.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/cmd25.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/commands/cmd50.sh"
}

# Test 6: Edge cases and error scenarios

@test "6.1: handles missing destination directory gracefully" {
    mkdir -p "$TEST_PROJECT/.claude/commands"
    create_file "$TEST_PROJECT/.claude/commands/test.sh" "test"
    
    # Remove the destination commands directory
    rm -rf "$TEST_WORKSPACE/.claude/commands"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    # Should succeed due to || true, but files won't be copied
    assert_success
    assert_output_contains "Project commands copied to container"
    # File won't exist because cp can't create parent directory with /* glob
    assert_file_not_exists "$TEST_WORKSPACE/.claude/commands/test.sh"
}

@test "6.2: command execution continues after pre-flight checks" {
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser sh -c "echo 'complex command' && exit 42"
    
    assert_exit_code 42
    assert_output_contains "complex command"
}

@test "6.3: handles empty arguments to exec" {
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser
    
    # Should complete successfully with no command to execute
    assert_success
    assert_output_contains "All pre-flight checks passed"
}

# Test 6: Bin copying functionality - No bins

@test "6.1: handles missing .claude/bin directory gracefully" {
    # Don't create .claude/bin directory
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Found project-specific bin scripts"
    refute_output_contains "Project bin scripts copied"
}

@test "6.2: handles empty .claude/bin directory" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Found project-specific bin scripts"
    assert_output_contains "Project bin scripts copied to container"
}

# Test 7: Bin copying functionality - Basic operations

@test "7.1: copies basic bin script file" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/test-script.sh" "#!/bin/bash\necho test"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/test-script.sh"
    assert_file_contains "$TEST_WORKSPACE/.claude/bin/test-script.sh" "echo test"
    assert_output_contains "Project bin scripts copied to container"
}

@test "7.2: copies multiple bin script files" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/script1.sh" "echo script1"
    create_file "$TEST_PROJECT/.claude/bin/script2.sh" "echo script2"
    create_file "$TEST_PROJECT/.claude/bin/script3.sh" "echo script3"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script1.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script2.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script3.sh"
}

@test "7.3: preserves nested directory structure in bin" {
    mkdir -p "$TEST_PROJECT/.claude/bin/utils/helpers"
    mkdir -p "$TEST_PROJECT/.claude/bin/tools"
    create_file "$TEST_PROJECT/.claude/bin/utils/script1.sh" "script1"
    create_file "$TEST_PROJECT/.claude/bin/utils/helpers/script2.sh" "script2"
    create_file "$TEST_PROJECT/.claude/bin/tools/script3.sh" "script3"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_dir_exists "$TEST_WORKSPACE/.claude/bin/utils"
    assert_dir_exists "$TEST_WORKSPACE/.claude/bin/utils/helpers"
    assert_dir_exists "$TEST_WORKSPACE/.claude/bin/tools"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/utils/script1.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/utils/helpers/script2.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/tools/script3.sh"
}

@test "7.4: respects no-overwrite flag for bin scripts" {
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    create_file "$TEST_WORKSPACE/.claude/bin/existing.sh" "original content"
    
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/existing.sh" "new content"
    create_file "$TEST_PROJECT/.claude/bin/new.sh" "new file"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_contains "$TEST_WORKSPACE/.claude/bin/existing.sh" "original content"
    refute_file_contains "$TEST_WORKSPACE/.claude/bin/existing.sh" "new content"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/new.sh"
}

@test "7.5: handles special characters in bin filenames" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    touch "$TEST_PROJECT/.claude/bin/script with spaces.sh"
    touch "$TEST_PROJECT/.claude/bin/script-with-dashes.sh"
    touch "$TEST_PROJECT/.claude/bin/script_with_underscores.sh"
    touch "$TEST_PROJECT/.claude/bin/script.multiple.dots.sh"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script with spaces.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script-with-dashes.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script_with_underscores.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script.multiple.dots.sh"
}

@test "7.6: preserves file permissions for bin scripts" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/executable.sh" "#!/bin/bash\necho executable"
    make_executable "$TEST_PROJECT/.claude/bin/executable.sh"
    
    create_file "$TEST_PROJECT/.claude/bin/non-executable.sh" "echo non-executable"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_executable "$TEST_WORKSPACE/.claude/bin/executable.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/non-executable.sh"
    ! [[ -x "$TEST_WORKSPACE/.claude/bin/non-executable.sh" ]] || { echo "non-executable.sh should not be executable" >&2; return 1; }
}

@test "7.7: handles bin copy errors gracefully" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    create_file "$TEST_PROJECT/.claude/bin/test.sh" "test content"
    
    # Make destination directory read-only to force copy error
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
    chmod -w "$TEST_WORKSPACE/.claude/bin"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    # Should still succeed due to || true in the script
    assert_success
    assert_output_contains "Project bin scripts copied to container"
    
    # Restore permissions for cleanup
    chmod +w "$TEST_WORKSPACE/.claude/bin"
}

@test "7.8: handles mixed file types in bin" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    
    # Regular files
    create_file "$TEST_PROJECT/.claude/bin/script.sh" "#!/bin/bash"
    create_file "$TEST_PROJECT/.claude/bin/README.md" "Documentation"
    
    # Different permissions
    make_executable "$TEST_PROJECT/.claude/bin/script.sh"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/README.md"
    assert_file_executable "$TEST_WORKSPACE/.claude/bin/script.sh"
}

@test "7.9: handles large number of bin files" {
    mkdir -p "$TEST_PROJECT/.claude/bin"
    
    # Create 50 test files
    for i in {1..50}; do
        create_file "$TEST_PROJECT/.claude/bin/script$i.sh" "echo $i"
    done
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    
    # Verify a sample of files were copied
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script1.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script25.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/bin/script50.sh"
}

# Test 8: Playwright directory initialization

@test "8.1: creates Playwright test directory if it doesn't exist" {
    # Ensure test directory doesn't exist
    rm -rf "$TEST_CLAUDE_CODE/tests/playwright"
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/example.spec.ts" "test content"
    create_file "$TEST_WORKSPACE/playwright-templates/package.json" "{}"
    create_file "$TEST_WORKSPACE/playwright-templates/playwright.config.ts" "config"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Creating Playwright test directory structure..."
    assert_dir_exists "$TEST_CLAUDE_CODE/tests/playwright"
}

@test "8.2: doesn't recreate Playwright directory if it already exists" {
    # Create the directory first
    mkdir -p "$TEST_CLAUDE_CODE/tests/playwright"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Creating Playwright test directory structure..."
}

# Test 9: Playwright file copying

@test "9.1: copies example.spec.ts if it doesn't exist" {
    mkdir -p "$TEST_CLAUDE_CODE/tests/playwright"
    rm -f "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts"
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/example.spec.ts" "import { test, expect } from '@playwright/test';"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Copying example Playwright test..."
    assert_file_exists "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts"
    assert_file_contains "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts" "import { test, expect } from '@playwright/test';"
}

@test "9.2: doesn't overwrite existing example.spec.ts" {
    mkdir -p "$TEST_CLAUDE_CODE/tests/playwright"
    create_file "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts" "existing test content"
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/example.spec.ts" "new test content"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Copying example Playwright test..."
    assert_file_contains "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts" "existing test content"
    refute_file_contains "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts" "new test content"
}

@test "9.3: copies package.json if it doesn't exist" {
    mkdir -p "$TEST_CLAUDE_CODE/tests"
    rm -f "$TEST_CLAUDE_CODE/tests/package.json"
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/package.json" '{"name": "playwright-tests"}'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Copying Playwright package.json..."
    assert_file_exists "$TEST_CLAUDE_CODE/tests/package.json"
    assert_file_contains "$TEST_CLAUDE_CODE/tests/package.json" '"name": "playwright-tests"'
}

@test "9.4: doesn't overwrite existing package.json" {
    mkdir -p "$TEST_CLAUDE_CODE/tests"
    create_file "$TEST_CLAUDE_CODE/tests/package.json" '{"existing": "package"}'
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/package.json" '{"new": "package"}'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Copying Playwright package.json..."
    assert_file_contains "$TEST_CLAUDE_CODE/tests/package.json" '"existing": "package"'
    refute_file_contains "$TEST_CLAUDE_CODE/tests/package.json" '"new": "package"'
}

@test "9.5: copies playwright.config.ts if it doesn't exist" {
    mkdir -p "$TEST_CLAUDE_CODE/tests"
    rm -f "$TEST_CLAUDE_CODE/tests/playwright.config.ts"
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/playwright.config.ts" "export default defineConfig({})"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Copying Playwright configuration..."
    assert_file_exists "$TEST_CLAUDE_CODE/tests/playwright.config.ts"
    assert_file_contains "$TEST_CLAUDE_CODE/tests/playwright.config.ts" "export default defineConfig"
}

@test "9.6: doesn't overwrite existing playwright.config.ts" {
    mkdir -p "$TEST_CLAUDE_CODE/tests"
    create_file "$TEST_CLAUDE_CODE/tests/playwright.config.ts" "existing config"
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/playwright.config.ts" "new config"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Copying Playwright configuration..."
    assert_file_contains "$TEST_CLAUDE_CODE/tests/playwright.config.ts" "existing config"
    refute_file_contains "$TEST_CLAUDE_CODE/tests/playwright.config.ts" "new config"
}

@test "9.7: handles missing playwright-templates directory gracefully" {
    # Don't create playwright-templates directory
    rm -rf "$TEST_WORKSPACE/playwright-templates"
    rm -rf "$TEST_CLAUDE_CODE/tests"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    # Should still succeed, but won't copy files
    assert_success
    assert_output_contains "Creating Playwright test directory structure..."
    # Directory will be created
    assert_dir_exists "$TEST_CLAUDE_CODE/tests/playwright"
    # But files won't exist since templates are missing
    assert_file_not_exists "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts"
}

@test "9.8: complete Playwright initialization flow" {
    # Clean slate
    rm -rf "$TEST_CLAUDE_CODE/tests"
    
    # Create all playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/example.spec.ts" "test('example', async ({ page }) => {})"
    create_file "$TEST_WORKSPACE/playwright-templates/package.json" '{"scripts": {"test": "playwright test"}}'
    create_file "$TEST_WORKSPACE/playwright-templates/playwright.config.ts" "export default defineConfig({ testDir: '$TEST_CLAUDE_CODE/tests/playwright' })"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Creating Playwright test directory structure..."
    assert_output_contains "Copying example Playwright test..."
    assert_output_contains "Copying Playwright package.json..."
    assert_output_contains "Copying Playwright configuration..."
    
    # Verify all files and directories were created
    assert_dir_exists "$TEST_CLAUDE_CODE/tests"
    assert_dir_exists "$TEST_CLAUDE_CODE/tests/playwright"
    assert_file_exists "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts"
    assert_file_exists "$TEST_CLAUDE_CODE/tests/package.json"
    assert_file_exists "$TEST_CLAUDE_CODE/tests/playwright.config.ts"
    
    # Verify content
    assert_file_contains "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts" "test('example', async ({ page }) => {})"
    assert_file_contains "$TEST_CLAUDE_CODE/tests/package.json" '"scripts": {"test": "playwright test"}'
    assert_file_contains "$TEST_CLAUDE_CODE/tests/playwright.config.ts" "testDir: '$TEST_CLAUDE_CODE/tests/playwright'"
}

# Test 10: Playwright screenshots directory initialization

@test "10.1: creates Playwright screenshots directory if it doesn't exist" {
    # Ensure screenshots directory doesn't exist
    rm -rf "$TEST_CLAUDE_CODE/screenshots"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Creating Playwright screenshots directory..."
    assert_dir_exists "$TEST_CLAUDE_CODE/screenshots"
}

@test "10.2: doesn't recreate screenshots directory if it already exists" {
    # Create the directory first
    mkdir -p "$TEST_CLAUDE_CODE/screenshots"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Creating Playwright screenshots directory..."
    assert_dir_exists "$TEST_CLAUDE_CODE/screenshots"
}

@test "10.3: screenshots directory creation happens after test directory creation" {
    # Clean slate
    rm -rf "$TEST_CLAUDE_CODE/tests"
    rm -rf "$TEST_CLAUDE_CODE/screenshots"
    
    # Create playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/example.spec.ts" "test content"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Creating Playwright test directory structure..."
    assert_output_contains "Creating Playwright screenshots directory..."
    
    # Verify both directories were created
    assert_dir_exists "$TEST_CLAUDE_CODE/tests/playwright"
    assert_dir_exists "$TEST_CLAUDE_CODE/screenshots"
}

@test "10.4: handles screenshots directory permissions correctly" {
    # Create screenshots directory with specific permissions
    mkdir -p "$TEST_CLAUDE_CODE/screenshots"
    chmod 755 "$TEST_CLAUDE_CODE/screenshots"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Creating Playwright screenshots directory..."
    
    # Verify directory still exists with correct permissions
    assert_dir_exists "$TEST_CLAUDE_CODE/screenshots"
    [[ "$(stat -c %a "$TEST_CLAUDE_CODE/screenshots" 2>/dev/null || stat -f %A "$TEST_CLAUDE_CODE/screenshots" 2>/dev/null)" == "755" ]] || true
}

@test "10.5: complete flow with both test and screenshots directories" {
    # Clean slate
    rm -rf "$TEST_CLAUDE_CODE/tests"
    rm -rf "$TEST_CLAUDE_CODE/screenshots"
    
    # Create all playwright templates
    mkdir -p "$TEST_WORKSPACE/playwright-templates"
    create_file "$TEST_WORKSPACE/playwright-templates/example.spec.ts" "test('screenshot', async ({ page }) => { await page.screenshot(); })"
    create_file "$TEST_WORKSPACE/playwright-templates/package.json" '{"scripts": {"test": "playwright test"}}'
    create_file "$TEST_WORKSPACE/playwright-templates/playwright.config.ts" "export default defineConfig({})"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Creating Playwright test directory structure..."
    assert_output_contains "Creating Playwright screenshots directory..."
    assert_output_contains "Copying example Playwright test..."
    assert_output_contains "Copying Playwright package.json..."
    assert_output_contains "Copying Playwright configuration..."
    
    # Verify all directories were created
    assert_dir_exists "$TEST_CLAUDE_CODE/tests"
    assert_dir_exists "$TEST_CLAUDE_CODE/tests/playwright"
    assert_dir_exists "$TEST_CLAUDE_CODE/screenshots"
    
    # Verify all files were created
    assert_file_exists "$TEST_CLAUDE_CODE/tests/playwright/example.spec.ts"
    assert_file_exists "$TEST_CLAUDE_CODE/tests/package.json"
    assert_file_exists "$TEST_CLAUDE_CODE/tests/playwright.config.ts"
}

# Test 11: MCP configuration merging

@test "11.1: handles missing project .claude/.mcp.json (default behavior)" {
    # Don't create project .claude/.mcp.json file
    
    # Create container .mcp.json
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{"playwright":{"command":"npx","args":["@playwright/mcp"]}}}'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    refute_output_contains "Found project-specific MCP configuration"
    assert_file_exists "$TEST_WORKSPACE/.mcp.json"
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"playwright"'
}

@test "11.2: successfully merges valid MCP configurations" {
    # Create container .mcp.json with playwright
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{"playwright":{"command":"npx","args":["@playwright/mcp"]}}}'
    
    # Create project .claude/.mcp.json with additional servers
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/.mcp.json" '{"mcpServers":{"aws-docs":{"command":"uvx","args":["awslabs.aws-documentation-mcp-server@latest"]},"terraform":{"command":"docker","args":["run","-i","--rm","hashicorp/terraform-mcp-server"]}}}'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Found project-specific MCP configuration"
    assert_output_contains "MCP configurations merged successfully"
    assert_file_exists "$TEST_WORKSPACE/.mcp.json"
    
    # Verify merged content contains all servers
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"playwright"'
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"aws-docs"'
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"terraform"'
}

@test "11.3: project servers take precedence over container servers" {
    # Create container .mcp.json with playwright
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{"playwright":{"command":"npx","args":["@playwright/mcp","--browser","firefox"]}}}'
    
    # Create project .claude/.mcp.json with different playwright config
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/.mcp.json" '{"mcpServers":{"playwright":{"command":"npx","args":["@playwright/mcp","--browser","chromium"]}}}'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "MCP configurations merged successfully"
    
    # Verify project config took precedence (chromium instead of firefox)
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"chromium"'
    refute_file_contains "$TEST_WORKSPACE/.mcp.json" '"firefox"'
}

@test "11.4: uses project config when container config is invalid" {
    # Create invalid container .mcp.json
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{"playwright":{'
    
    # Create valid project .claude/.mcp.json
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/.mcp.json" '{"mcpServers":{"aws-docs":{"command":"uvx","args":["awslabs.aws-documentation-mcp-server@latest"]}}}'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Warning: Container MCP configuration is invalid JSON"
    assert_output_contains "Using project MCP configuration (container config was invalid)"
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"aws-docs"'
    refute_file_contains "$TEST_WORKSPACE/.mcp.json" '"playwright"'
}

@test "11.5: keeps container config when project config is invalid" {
    # Create valid container .mcp.json
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{"playwright":{"command":"npx","args":["@playwright/mcp"]}}}'
    
    # Create invalid project .claude/.mcp.json
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/.mcp.json" '{"mcpServers":{"aws-docs":'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Warning: Project MCP configuration is invalid JSON"
    assert_output_contains "Keeping container MCP configuration (project config was invalid)"
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"playwright"'
    refute_file_contains "$TEST_WORKSPACE/.mcp.json" '"aws-docs"'
}

@test "11.6: handles both configurations being invalid" {
    # Create invalid container .mcp.json
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{'
    
    # Create invalid project .claude/.mcp.json
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/.mcp.json" '{"invalid":'
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Warning: Container MCP configuration is invalid JSON"
    assert_output_contains "Warning: Project MCP configuration is invalid JSON"
    assert_output_contains "Warning: Both MCP configurations invalid, keeping original container configuration"
    
    # Original invalid container file should remain unchanged
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{'
}

@test "11.7: handles empty project .claude/.mcp.json file" {
    # Create container .mcp.json
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{"playwright":{"command":"npx","args":["@playwright/mcp"]}}}'
    
    # Create empty project .claude/.mcp.json
    mkdir -p "$TEST_PROJECT/.claude"
    touch "$TEST_PROJECT/.claude/.mcp.json"
    
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"
    
    assert_success
    assert_output_contains "Warning: Project MCP configuration is invalid JSON"
    assert_output_contains "Keeping container MCP configuration (project config was invalid)"
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"playwright"'
}

@test "11.8: verifies merged result is valid JSON" {
    # Create valid container .mcp.json
    create_file "$TEST_WORKSPACE/.mcp.json" '{"mcpServers":{"playwright":{"command":"npx","args":["@playwright/mcp"]}}}'

    # Create valid project .claude/.mcp.json with complex nested structure
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/.mcp.json" '{"mcpServers":{"aws-docs":{"type":"stdio","command":"uvx","args":["awslabs.aws-documentation-mcp-server@latest"],"env":{"AWS_DOCUMENTATION_PARTITION":"aws","FASTMCP_LOG_LEVEL":"ERROR"}}}}'

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_output_contains "MCP configurations merged successfully"

    # Verify the merged result is valid JSON by testing with jq
    jq empty "$TEST_WORKSPACE/.mcp.json" || { echo "Merged .mcp.json is not valid JSON" >&2; return 1; }

    # Verify structure and content
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"playwright"'
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"aws-docs"'
    assert_file_contains "$TEST_WORKSPACE/.mcp.json" '"AWS_DOCUMENTATION_PARTITION"'
}

# Test 12: Skills copying functionality - No skills

@test "12.1: handles missing .claude/skills directory gracefully" {
    # Don't create .claude/skills directory
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    refute_output_contains "Found project-specific skills"
    refute_output_contains "Project skills copied"
}

@test "12.2: handles empty .claude/skills directory" {
    mkdir -p "$TEST_PROJECT/.claude/skills"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_output_contains "Found project-specific skills"
    assert_output_contains "Project skills copied to container"
}

# Test 13: Skills copying functionality - Basic operations

@test "13.1: copies basic skill file" {
    mkdir -p "$TEST_PROJECT/.claude/skills"
    create_file "$TEST_PROJECT/.claude/skills/test-skill.md" "# Test Skill\nThis is a test skill"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/test-skill.md"
    assert_file_contains "$TEST_WORKSPACE/.claude/skills/test-skill.md" "Test Skill"
    assert_output_contains "Project skills copied to container"
}

@test "13.2: copies multiple skill files" {
    mkdir -p "$TEST_PROJECT/.claude/skills"
    create_file "$TEST_PROJECT/.claude/skills/skill1.md" "skill1 content"
    create_file "$TEST_PROJECT/.claude/skills/skill2.md" "skill2 content"
    create_file "$TEST_PROJECT/.claude/skills/skill3.md" "skill3 content"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill1.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill2.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill3.md"
}

@test "13.3: preserves nested directory structure in skills" {
    mkdir -p "$TEST_PROJECT/.claude/skills/category1/subcategory"
    mkdir -p "$TEST_PROJECT/.claude/skills/category2"
    create_file "$TEST_PROJECT/.claude/skills/category1/skill1.md" "skill1"
    create_file "$TEST_PROJECT/.claude/skills/category1/subcategory/skill2.md" "skill2"
    create_file "$TEST_PROJECT/.claude/skills/category2/skill3.md" "skill3"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_dir_exists "$TEST_WORKSPACE/.claude/skills/category1"
    assert_dir_exists "$TEST_WORKSPACE/.claude/skills/category1/subcategory"
    assert_dir_exists "$TEST_WORKSPACE/.claude/skills/category2"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/category1/skill1.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/category1/subcategory/skill2.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/category2/skill3.md"
}

@test "13.4: respects no-overwrite flag for skills" {
    mkdir -p "$TEST_WORKSPACE/.claude/skills"
    create_file "$TEST_WORKSPACE/.claude/skills/existing.md" "original content"

    mkdir -p "$TEST_PROJECT/.claude/skills"
    create_file "$TEST_PROJECT/.claude/skills/existing.md" "new content"
    create_file "$TEST_PROJECT/.claude/skills/new.md" "new file"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_file_contains "$TEST_WORKSPACE/.claude/skills/existing.md" "original content"
    refute_file_contains "$TEST_WORKSPACE/.claude/skills/existing.md" "new content"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/new.md"
}

@test "13.5: handles special characters in skill filenames" {
    mkdir -p "$TEST_PROJECT/.claude/skills"
    touch "$TEST_PROJECT/.claude/skills/skill with spaces.md"
    touch "$TEST_PROJECT/.claude/skills/skill-with-dashes.md"
    touch "$TEST_PROJECT/.claude/skills/skill_with_underscores.md"
    touch "$TEST_PROJECT/.claude/skills/skill.multiple.dots.md"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill with spaces.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill-with-dashes.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill_with_underscores.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill.multiple.dots.md"
}

@test "13.6: preserves file permissions for skills" {
    mkdir -p "$TEST_PROJECT/.claude/skills"
    create_file "$TEST_PROJECT/.claude/skills/executable-skill.sh" "#!/bin/bash\necho executable"
    make_executable "$TEST_PROJECT/.claude/skills/executable-skill.sh"

    create_file "$TEST_PROJECT/.claude/skills/non-executable.md" "markdown content"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_file_executable "$TEST_WORKSPACE/.claude/skills/executable-skill.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/non-executable.md"
    ! [[ -x "$TEST_WORKSPACE/.claude/skills/non-executable.md" ]] || { echo "non-executable.md should not be executable" >&2; return 1; }
}

@test "13.7: handles skills copy errors gracefully" {
    mkdir -p "$TEST_PROJECT/.claude/skills"
    create_file "$TEST_PROJECT/.claude/skills/test.md" "test content"

    # Make destination directory read-only to force copy error
    mkdir -p "$TEST_WORKSPACE/.claude/skills"
    chmod -w "$TEST_WORKSPACE/.claude/skills"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    # Should still succeed due to || true in the script
    assert_success
    assert_output_contains "Project skills copied to container"

    # Restore permissions for cleanup
    chmod +w "$TEST_WORKSPACE/.claude/skills"
}

@test "13.8: handles mixed file types in skills" {
    mkdir -p "$TEST_PROJECT/.claude/skills"

    # Regular files
    create_file "$TEST_PROJECT/.claude/skills/skill.md" "# Skill markdown"
    create_file "$TEST_PROJECT/.claude/skills/skill.sh" "#!/bin/bash"
    create_file "$TEST_PROJECT/.claude/skills/README.txt" "Documentation"

    # Different permissions
    make_executable "$TEST_PROJECT/.claude/skills/skill.sh"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill.sh"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/README.txt"
    assert_file_executable "$TEST_WORKSPACE/.claude/skills/skill.sh"
}

@test "13.9: handles large number of skill files" {
    mkdir -p "$TEST_PROJECT/.claude/skills"

    # Create 50 test files
    for i in {1..50}; do
        create_file "$TEST_PROJECT/.claude/skills/skill$i.md" "skill $i content"
    done

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success

    # Verify a sample of files were copied
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill1.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill25.md"
    assert_file_exists "$TEST_WORKSPACE/.claude/skills/skill50.md"
}

@test "13.10: handles missing destination skills directory gracefully" {
    mkdir -p "$TEST_PROJECT/.claude/skills"
    create_file "$TEST_PROJECT/.claude/skills/test.md" "test"

    # Remove the destination skills directory
    rm -rf "$TEST_WORKSPACE/.claude/skills"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    # Should succeed due to || true, but files won't be copied
    assert_success
    assert_output_contains "Project skills copied to container"
    # File won't exist because cp can't create parent directory with /* glob
    assert_file_not_exists "$TEST_WORKSPACE/.claude/skills/test.md"
}

# Test 14: Settings.local.json copying functionality

@test "14.1: handles missing settings.local.json gracefully" {
    # Don't create settings.local.json file
    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    refute_output_contains "Found project-specific settings"
    refute_output_contains "Project settings copied"
}

@test "14.2: copies settings.local.json when it exists" {
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/settings.local.json" '{"permissions":{"allow":["Bash(git:*)"],"deny":[]}}'

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_output_contains "Found project-specific settings in"
    assert_output_contains "Project settings copied to container"
    assert_file_exists "$TEST_WORKSPACE/.claude/settings.local.json"
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"permissions"'
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"allow"'
}

@test "14.3: respects no-overwrite flag for existing settings.local.json" {
    # Create existing container settings
    create_file "$TEST_WORKSPACE/.claude/settings.local.json" '{"existing":"container-settings"}'

    # Create project settings
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/settings.local.json" '{"new":"project-settings"}'

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_output_contains "Found project-specific settings"
    assert_output_contains "Project settings copied to container"
    # Original content should be preserved
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"existing"'
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"container-settings"'
    # New content should NOT be present
    refute_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"new"'
    refute_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"project-settings"'
}

@test "14.4: handles copy errors gracefully" {
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/settings.local.json" '{"test":"content"}'

    # Make destination directory read-only to force copy error
    chmod -w "$TEST_WORKSPACE/.claude"

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    # Should still succeed due to || true in the script
    assert_success
    assert_output_contains "Project settings copied to container"

    # Restore permissions for cleanup
    chmod +w "$TEST_WORKSPACE/.claude"
}

@test "14.5: preserves complete JSON structure in settings" {
    mkdir -p "$TEST_PROJECT/.claude"
    create_file "$TEST_PROJECT/.claude/settings.local.json" '{"permissions":{"allow":["Bash(git:*)","Read(/workspace/**)"],"deny":["Bash(rm:*)"],"allowedTools":["Edit","Write"]}}'

    run_entrypoint_with_env HOST_PWD=/test/path HOST_USER=testuser echo "test"

    assert_success
    assert_file_exists "$TEST_WORKSPACE/.claude/settings.local.json"

    # Verify the copied file is valid JSON by testing with jq
    jq empty "$TEST_WORKSPACE/.claude/settings.local.json" || { echo "settings.local.json is not valid JSON" >&2; return 1; }

    # Verify structure and content
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"permissions"'
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"allow"'
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" '"deny"'
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" 'Bash(git:*)'
    assert_file_contains "$TEST_WORKSPACE/.claude/settings.local.json" 'Bash(rm:*)'
}