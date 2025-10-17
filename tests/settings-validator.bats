#!/usr/bin/env bats

# Load test helper functions
load test_helper

# Test 1: Settings file loading

@test "1.1: settings.json file exists and is valid JSON" {
    assert_file_exists "$BATS_TEST_DIRNAME/../assets/.claude/settings.json"
    
    # Verify it's valid JSON
    run node -e "JSON.parse(require('fs').readFileSync('$BATS_TEST_DIRNAME/../assets/.claude/settings.json', 'utf8'))"
    assert_success
}

@test "1.2: settings.json contains deny patterns" {
    run node -e "
        const settings = JSON.parse(require('fs').readFileSync('$BATS_TEST_DIRNAME/../assets/.claude/settings.json', 'utf8'));
        if (!settings.permissions || !settings.permissions.deny || !Array.isArray(settings.permissions.deny)) {
            process.exit(1);
        }
        console.log('Deny patterns found:', settings.permissions.deny.length);
    "
    assert_success
    assert_output_contains "Deny patterns found:"
}

# Test 2: Deny pattern validation - positive matches (should be denied)

@test "2.1: blocks exact .env files" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/home/user/.env"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/workspace/project/.env"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/nested/deep/path/.env"
    assert_failure
    assert_output_contains "DENIED"
}

@test "2.2: blocks files starting with .env" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/.env-local"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/.env-unittest"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/docs/.env-example"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/.env.production"
    assert_failure
    assert_output_contains "DENIED"
}

@test "2.3: blocks dotenv files" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/project/dotenv"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/nested/path/dotenv"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/config/my-dotenv"
    assert_failure
    assert_output_contains "DENIED"
}

@test "2.4: blocks env file without dot" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/config/env"
    assert_failure
    assert_output_contains "DENIED"
}

# Test 3: Deny pattern validation - negative matches (should be allowed)

@test "3.1: allows non-matching environment files" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/home/user/environment.txt"
    assert_success
    assert_output_contains "ALLOWED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/project/env-config.json"
    assert_success
    assert_output_contains "ALLOWED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/development.env"
    assert_success
    assert_output_contains "ALLOWED"
}

@test "3.2: allows other dot files" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/.gitignore"
    assert_success
    assert_output_contains "ALLOWED"
}

@test "3.3: allows files containing but not ending with dotenv" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/config/dotenv-safe.js"
    assert_success
    assert_output_contains "ALLOWED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/config/dotenvfile.txt"
    assert_success
    assert_output_contains "ALLOWED"
}

@test "3.4: allows files with env in the name but not matching patterns" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/project/envoy.yaml"
    assert_success
    assert_output_contains "ALLOWED"
}

# Test 4: Edge cases and special characters

@test "4.1: handles paths with spaces" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/path with spaces/.env"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/path with spaces/config.txt"
    assert_success
    assert_output_contains "ALLOWED"
}

@test "4.2: handles paths with special characters" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/path-with-dashes/.env"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/path_with_underscores/.env.local"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/path.with.dots/dotenv"
    assert_failure
    assert_output_contains "DENIED"
}

@test "4.3: handles very long paths" {
    local long_path="/very/deep/nested/directory/structure/that/goes/on/and/on/and/on/with/many/levels/.env"
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "$long_path"
    assert_failure
    assert_output_contains "DENIED"
}

@test "4.4: handles empty path components" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "//double//slashes//.env"
    assert_failure
    assert_output_contains "DENIED"
}

@test "4.5: validates all patterns are tested" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" --show-patterns
    assert_success
    assert_output_contains "Read(**/.env)"
    assert_output_contains "Read(**/.env*)"
    assert_output_contains "Read(**/dotenv)"
    assert_output_contains "Read(**/*dotenv)"
    assert_output_contains "Read(**/env)"
    assert_output_contains "Read(**/*sites*.ini*)"
}

# Test 5: Sites.ini pattern validation - positive matches (should be denied)

@test "5.1: blocks exact sites.ini files" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/workspace/project/sites.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/config/sites.ini"
    assert_failure
    assert_output_contains "DENIED"
}

@test "5.2: blocks sites.ini environment variations" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites-local.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites-prod.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites_test.ini"
    assert_failure
    assert_output_contains "DENIED"
}

@test "5.3: blocks sites.ini backup variations" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.bkp.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.ini.old"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.ini.backup"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.ini~"
    assert_failure
    assert_output_contains "DENIED"
}

@test "5.4: blocks prefixed sites.ini variations" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/mysites.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/.sites.ini"
    assert_failure
    assert_output_contains "DENIED"
}

@test "5.5: blocks sites.config.ini variations" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.config.ini"
    assert_failure
    assert_output_contains "DENIED"
}

# Test 6: Sites.ini pattern validation - negative matches (should be allowed)

@test "6.1: blocks files containing 'sites' in name with .ini extension" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/websites.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/prerequisites.ini"
    assert_failure
    assert_output_contains "DENIED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/configuration.ini"
    assert_success
    assert_output_contains "ALLOWED"
}

@test "6.2: allows sites files with different extensions" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.conf"
    assert_success
    assert_output_contains "ALLOWED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.json"
    assert_success
    assert_output_contains "ALLOWED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/sites.xml"
    assert_success
    assert_output_contains "ALLOWED"
}

@test "6.3: allows site-config.json and similar variations" {
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/site-config.json"
    assert_success
    assert_output_contains "ALLOWED"
    
    run node "$BATS_TEST_DIRNAME/settings-validator-helper.js" "/app/site.ini"
    assert_success
    assert_output_contains "ALLOWED"
}