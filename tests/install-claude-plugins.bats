#!/usr/bin/env bats
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Tests for the start-time plugin fetch with its baked backup

SCRIPT="$BATS_TEST_DIRNAME/../assets/install-claude-plugins.sh"

setup() {
    export WORK="/tmp/test-plugins-$$-$BATS_TEST_NUMBER"
    rm -rf "$WORK"
    mkdir -p "$WORK"
    export CLAUDE_PLUGINS_DIR="$WORK/opt/current"
    export CLAUDE_PLUGINS_REF="main"
    export CLAUDE_PLUGINS_FETCH_TIMEOUT="10"
    unset CLAUDE_PLUGINS_FETCH
}

teardown() {
    rm -rf "$WORK"
}

# A marketplace repo with the given plugins and a marker file naming the version
make_marketplace() {
    local repo="$1" version="$2"
    shift 2
    mkdir -p "$repo"
    git -C "$repo" init --quiet --initial-branch=main
    local plugin
    for plugin in "$@"; do
        mkdir -p "$repo/plugins/$plugin/.claude-plugin"
        echo "{\"name\": \"$plugin\"}" > "$repo/plugins/$plugin/.claude-plugin/plugin.json"
    done
    echo "$version" > "$repo/VERSION"
    git -C "$repo" add -A
    git -C "$repo" -c user.name=test -c user.email=test@example.com commit --quiet -m "$version"
}

bake() {
    make_marketplace "$WORK/baked-src" "baked" workflow branch-beacon
    CLAUDE_PLUGINS_REPO="file://$WORK/baked-src" run "$SCRIPT" --bake
}

@test "bake: fetches the marketplace and prints every plugin dir" {
    bake

    [ "$status" -eq 0 ]
    [ "$(cat "$CLAUDE_PLUGINS_DIR/VERSION")" = "baked" ]
    [[ "$output" == *"$CLAUDE_PLUGINS_DIR/plugins/branch-beacon:$CLAUDE_PLUGINS_DIR/plugins/workflow"* ]]
    [ ! -d "$CLAUDE_PLUGINS_DIR/.git" ]
}

@test "bake: fails when the marketplace cannot be fetched" {
    CLAUDE_PLUGINS_REPO="file://$WORK/missing" run "$SCRIPT" --bake

    [ "$status" -eq 1 ]
    [[ "$output" == *"could not fetch plugins"* ]]
}

@test "start: replaces the baked copy with the latest commit" {
    bake
    make_marketplace "$WORK/live" "live" workflow branch-beacon new-mod

    CLAUDE_PLUGINS_REPO="file://$WORK/live" run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(cat "$CLAUDE_PLUGINS_DIR/VERSION")" = "live" ]
    [[ "$output" == *"loaded main@"* ]]
    [[ "$output" == *"$CLAUDE_PLUGINS_DIR/plugins/new-mod"* ]]
}

@test "start: keeps the baked copy when the fetch fails" {
    bake

    CLAUDE_PLUGINS_REPO="file://$WORK/unreachable" run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(cat "$CLAUDE_PLUGINS_DIR/VERSION")" = "baked" ]
    [[ "$output" == *"using the copy baked into the image"* ]]
    [[ "$output" == *"$CLAUDE_PLUGINS_DIR/plugins/workflow"* ]]
    [ ! -d "$CLAUDE_PLUGINS_DIR.incoming" ]
}

@test "start: keeps the baked copy when the fetched repo has no plugins" {
    bake
    mkdir -p "$WORK/old-layout/skills/hello"
    git -C "$WORK/old-layout" init --quiet --initial-branch=main
    echo "old" > "$WORK/old-layout/skills/hello/SKILL.md"
    git -C "$WORK/old-layout" add -A
    git -C "$WORK/old-layout" -c user.name=test -c user.email=test@example.com commit --quiet -m old

    CLAUDE_PLUGINS_REPO="file://$WORK/old-layout" run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(cat "$CLAUDE_PLUGINS_DIR/VERSION")" = "baked" ]
    [[ "$output" == *"has no plugins/*/.claude-plugin/plugin.json, using the copy baked into the image"* ]]
    [ ! -d "$CLAUDE_PLUGINS_DIR.incoming" ]
}

@test "start: a fetch cut off by the timeout never replaces the baked copy" {
    bake
    make_marketplace "$WORK/live" "live" workflow
    mkdir -p "$WORK/bin"
    printf '#!/bin/bash\nmkdir -p "${@: -1}/plugins/partial/.claude-plugin"\necho "{}" > "${@: -1}/plugins/partial/.claude-plugin/plugin.json"\nexit 124\n' > "$WORK/bin/timeout"
    chmod +x "$WORK/bin/timeout"

    PATH="$WORK/bin:$PATH" CLAUDE_PLUGINS_REPO="file://$WORK/live" run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(cat "$CLAUDE_PLUGINS_DIR/VERSION")" = "baked" ]
    [ ! -d "$CLAUDE_PLUGINS_DIR/plugins/partial" ]
    [ ! -d "$CLAUDE_PLUGINS_DIR.incoming" ]
    [[ "$output" == *"could not fetch the latest plugins"* ]]
}

@test "start: CLAUDE_PLUGINS_FETCH=0 skips the fetch" {
    bake
    make_marketplace "$WORK/live" "live" workflow

    CLAUDE_PLUGINS_FETCH=0 CLAUDE_PLUGINS_REPO="file://$WORK/live" run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(cat "$CLAUDE_PLUGINS_DIR/VERSION")" = "baked" ]
    [[ "$output" == *"fetch skipped"* ]]
}

@test "start: follows CLAUDE_PLUGINS_REF" {
    bake
    make_marketplace "$WORK/live" "main-version" workflow
    git -C "$WORK/live" checkout --quiet -b stable
    echo "stable-version" > "$WORK/live/VERSION"
    git -C "$WORK/live" -c user.name=test -c user.email=test@example.com commit --quiet -am stable

    CLAUDE_PLUGINS_REF=stable CLAUDE_PLUGINS_REPO="file://$WORK/live" run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(cat "$CLAUDE_PLUGINS_DIR/VERSION")" = "stable-version" ]
}

@test "start: stdout carries only the plugin dirs" {
    bake

    CLAUDE_PLUGINS_REPO="file://$WORK/unreachable" "$SCRIPT" > "$WORK/stdout" 2> /dev/null

    [ "$(cat "$WORK/stdout")" = "$CLAUDE_PLUGINS_DIR/plugins/branch-beacon:$CLAUDE_PLUGINS_DIR/plugins/workflow" ]
}

@test "start: reports when no plugins are available at all" {
    CLAUDE_PLUGINS_REPO="file://$WORK/unreachable" run "$SCRIPT"

    [ "$status" -eq 0 ]
    [[ "$output" == *"no plugins found"* ]]
}
