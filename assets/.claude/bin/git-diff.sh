#!/bin/bash
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Show uncommitted changes with helpful context

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# If no arguments provided, show usage
if [ $# -eq 0 ]; then
    echo "Usage: git-diff.sh <file>"
    echo "Shows git diff for a specific file with context and statistics"
    exit 1
fi

# Show diff with context for the specified file
git diff --color=always --unified=5 "$@" && echo "" && git diff --stat "$@"