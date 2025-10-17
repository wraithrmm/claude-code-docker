#!/bin/bash

# Run all test files in the tests directory

echo "Running test suite..."
echo "===================="

# Make test helper executable
chmod +x tests/test_helper.bash

# Find and make all test files executable
find tests -name "*.bats" -exec chmod +x {} \;

# Track test results
ALL_PASSED=true

# Run all bats test files
for test_file in tests/*.bats; do
    if [ -f "$test_file" ]; then
        test_name=$(basename "$test_file" .bats)
        echo ""
        echo "Running $test_name tests..."
        echo "=============================="
        bats "$test_file" "$@"
        if [ $? -ne 0 ]; then
            ALL_PASSED=false
        fi
    fi
done

# Show summary
echo ""
if [ "$ALL_PASSED" = true ]; then
    echo "All tests passed! ✓"
else
    echo "Some tests failed. See output above for details."
    exit 1
fi