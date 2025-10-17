#!/bin/bash

# Output assertion helper functions

# Check for usage instructions in output
assert_usage_message() {
    local expected_usage="$1"
    assert_output_contains "Usage:"
    if [[ -n "$expected_usage" ]]; then
        assert_output_contains "$expected_usage"
    fi
}

# Verify guidance/next steps output
assert_next_steps_message() {
    local output_to_check="${1:-$output}"
    
    # Check for common next steps patterns
    echo "$output_to_check" | grep -E "(Next steps:|To continue:|You can now:|Note:|Now you can)" >/dev/null || {
        echo "Output does not contain next steps guidance" >&2
        echo "Actual output: $output_to_check" >&2
        return 1
    }
}

# Check error messages with standard format
assert_error_message() {
    local expected_error="$1"
    assert_failure
    assert_output_contains "Error:"
    if [[ -n "$expected_error" ]]; then
        assert_output_contains "$expected_error"
    fi
}

# Assert success message with optional content
assert_success_message() {
    local expected_content="$1"
    assert_success
    if [[ -n "$expected_content" ]]; then
        assert_output_contains "$expected_content"
    fi
}

# Check for file creation confirmation
assert_file_created_message() {
    local file_type="$1"
    local file_name="$2"
    
    assert_output_contains "created"
    if [[ -n "$file_type" ]]; then
        assert_output_contains "$file_type"
    fi
    if [[ -n "$file_name" ]]; then
        assert_output_contains "$file_name"
    fi
}

# Check for standard warning messages
assert_warning_message() {
    local warning_content="$1"
    
    assert_output_contains "Warning:"
    if [[ -n "$warning_content" ]]; then
        assert_output_contains "$warning_content"
    fi
}

# Assert output matches a pattern (regex)
assert_output_matches() {
    local pattern="$1"
    echo "$output" | grep -E "$pattern" >/dev/null || {
        echo "Output does not match pattern: $pattern" >&2
        echo "Actual output: $output" >&2
        return 1
    }
}

# Assert output does not match a pattern (regex)
refute_output_matches() {
    local pattern="$1"
    ! echo "$output" | grep -E "$pattern" >/dev/null || {
        echo "Output unexpectedly matches pattern: $pattern" >&2
        echo "Actual output: $output" >&2
        return 1
    }
}

# Assert output contains multiple strings
assert_output_contains_all() {
    local strings=("$@")
    
    for str in "${strings[@]}"; do
        assert_output_contains "$str"
    done
}

# Assert output contains at least one of the provided strings
assert_output_contains_any() {
    local strings=("$@")
    local found=false
    
    for str in "${strings[@]}"; do
        if echo "$output" | grep -F -q -- "$str"; then
            found=true
            break
        fi
    done
    
    if [[ "$found" != true ]]; then
        echo "Output does not contain any of: ${strings[*]}" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Assert output line count
assert_line_count() {
    local expected_count="$1"
    local actual_count=$(echo "$output" | wc -l)
    
    [[ "$actual_count" -eq "$expected_count" ]] || {
        echo "Expected $expected_count lines but got $actual_count" >&2
        echo "Actual output: $output" >&2
        return 1
    }
}

# Assert specific line content
assert_line() {
    local line_number="$1"
    local expected_content="$2"
    local actual_line=$(echo "$output" | sed -n "${line_number}p")
    
    [[ "$actual_line" == "$expected_content" ]] || {
        echo "Line $line_number does not match expected content" >&2
        echo "Expected: $expected_content" >&2
        echo "Actual: $actual_line" >&2
        return 1
    }
}