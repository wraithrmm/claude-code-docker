#!/bin/bash

# Test helper functions for the .claude/bin PATH tests

# Standard setup for bin script tests
setup_bin_test() {
    create_test_workspace
    mkdir -p "$TEST_WORKSPACE/.claude/bin"
}
