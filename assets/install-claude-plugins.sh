#!/bin/bash
# SPDX-License-Identifier: PolyForm-Shield-1.0.0
# Copyright (c) 2025-present Richard Mann
# Licensed under the PolyForm Shield License 1.0.0
# https://polyformproject.org/licenses/shield/1.0.0/

# Fetches the latest Claude Code plugin marketplace into a fixed directory and
# prints the CLAUDE_CODE_PLUGIN_DIRS value for every plugin it holds.
#
#   install-claude-plugins.sh --bake   build time: the fetch must succeed
#   install-claude-plugins.sh          start time: keep the baked copy on failure
#
# Status lines go to stderr; stdout carries only the plugin dirs.

set -uo pipefail

CLAUDE_PLUGINS_REPO="${CLAUDE_PLUGINS_REPO:-https://github.com/wraithrmm/claude-workflow.git}"
CLAUDE_PLUGINS_REF="${CLAUDE_PLUGINS_REF:-main}"
CLAUDE_PLUGINS_DIR="${CLAUDE_PLUGINS_DIR:-/opt/claude-plugins/current}"
CLAUDE_PLUGINS_FETCH_TIMEOUT="${CLAUDE_PLUGINS_FETCH_TIMEOUT:-20}"
CLAUDE_PLUGINS_FETCH="${CLAUDE_PLUGINS_FETCH:-1}"

MODE="start"
if [[ "${1:-}" == "--bake" ]]; then
    MODE="bake"
fi

log() {
    echo "Claude plugins: $*" >&2
}

has_plugins() {
    compgen -G "$1/plugins/*/.claude-plugin/plugin.json" > /dev/null
}

plugin_dirs() {
    local dirs=()
    local manifest
    for manifest in "$CLAUDE_PLUGINS_DIR"/plugins/*/.claude-plugin/plugin.json; do
        [[ -f "$manifest" ]] && dirs+=("$(dirname "$(dirname "$manifest")")")
    done
    local IFS=":"
    echo "${dirs[*]}"
}

fetch() {
    local incoming="$1"
    rm -rf "$incoming"
    timeout "$CLAUDE_PLUGINS_FETCH_TIMEOUT" git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$CLAUDE_PLUGINS_REF" "$CLAUDE_PLUGINS_REPO" "$incoming" 2> /dev/null
}

incoming="$CLAUDE_PLUGINS_DIR.incoming"
mkdir -p "$(dirname "$CLAUDE_PLUGINS_DIR")"

if [[ "$CLAUDE_PLUGINS_FETCH" == "0" && "$MODE" == "start" ]]; then
    log "fetch skipped (CLAUDE_PLUGINS_FETCH=0), using the copy baked into the image"
elif fetch "$incoming"; then
    if has_plugins "$incoming"; then
        commit="$(git -C "$incoming" rev-parse --short HEAD 2> /dev/null || echo unknown)"
        rm -rf "$incoming/.git" "$CLAUDE_PLUGINS_DIR"
        mv "$incoming" "$CLAUDE_PLUGINS_DIR"
        log "loaded $CLAUDE_PLUGINS_REF@$commit from $CLAUDE_PLUGINS_REPO"
    else
        rm -rf "$incoming"
        if [[ "$MODE" == "bake" ]]; then
            log "$CLAUDE_PLUGINS_REPO ($CLAUDE_PLUGINS_REF) has no plugins/*/.claude-plugin/plugin.json"
            exit 1
        fi
        log "$CLAUDE_PLUGINS_REPO ($CLAUDE_PLUGINS_REF) has no plugins/*/.claude-plugin/plugin.json, using the copy baked into the image"
    fi
else
    rm -rf "$incoming"
    if [[ "$MODE" == "bake" ]]; then
        log "could not fetch plugins from $CLAUDE_PLUGINS_REPO ($CLAUDE_PLUGINS_REF)"
        exit 1
    fi
    log "could not fetch the latest plugins from $CLAUDE_PLUGINS_REPO ($CLAUDE_PLUGINS_REF), using the copy baked into the image"
fi

if ! has_plugins "$CLAUDE_PLUGINS_DIR"; then
    log "no plugins found in $CLAUDE_PLUGINS_DIR; the workflow skills will be unavailable"
    exit 0
fi

plugin_dirs
