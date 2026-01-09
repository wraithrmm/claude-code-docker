# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a Docker prototype for integrating Claude Code into a development environment. The project creates a containerized environment that combines a PHP/Apache base image with Claude Code installation with the objective of allowing developers to run Claude Code in a Docker container so that they can run multiple instances locally, at once, on any mapped codebase.

## Architecture

- **Base Image**: Uses a custom PHP/Apache base image
- **Runtime Environment**: Node.js LTS installed alongside PHP/Apache for Claude Code functionality
- **Working Directory**: `/workspace` is the designated directory for Claude Code projects within the container
- **Service Identity**: Tagged as `claudecode` service

## Docker Commands

Build the Docker image:

```bash
docker build -f Dockerfile -t claude-code-docker:local . --build-arg TAGGED_VERSION=local
```

Run the container:

```bash
docker run -it --rm \
  -v $(pwd):/workspace/project \
  -v ~/.claude.json:/opt/user-claude/.claude.json \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.claude:/opt/user-claude/.claude \
  -v /Users/claude-code:/Users/claude-code \
  -e HOST_PWD=$(pwd) \
  -e HOST_USER=$(whoami) \
  claude-code-docker:local \
  /bin/bash
```

Note: The container includes pre-configured MCP servers (like Playwright) in `/workspace/.mcp.json`. If your project has a `.claude/.mcp.json` file, it will be automatically merged with the container's MCP configuration on startup, with project servers taking precedence.

## Security Scanning

The repository includes `.trivyignore` to suppress base image security warnings (DS002) since the base image runs as root by design.

## Development Notes

- The container inherits the entrypoint from the base PHP/Apache image
- Claude Code is installed globally and available system-wide
- The `/workspace` directory is owned by `www-data:www-data` for proper permissions
- Node.js and npm versions are verified during build to ensure proper installation

## Testing

This repository includes a comprehensive test suite for the entrypoint script:

- **Test Framework**: BATS (Bash Automated Testing System)
- **Test Location**: `tests/` directory
- **Running Tests**: `./run-tests.sh` or `bats tests/entrypoint.bats`
- **CI Integration**: Tests run automatically in CircleCI before building

When modifying the entrypoint script, always run the test suite to ensure no regressions.

## Code Quality Checks

**CRITICAL: You MUST run both security scanning and linting after completing any development work on this Dockerfile.**

This repository includes Docker-based scanning tools that mirror the CircleCI pipeline checks. No local tool installation is required - everything runs in Docker containers.

### Available Scanning Tools

1. **Project Linter** (`run-linters`) - Runs all linters including:
   - JSON validation for all `.json` files in the project
   - Hadolint for Dockerfile best practices
2. **Security Scanner** (`run-security-scan`) - Uses Trivy to scan for vulnerabilities

**IMPORTANT**: Always use `./.claude/bin/run-linters` for validation. Do not use ad-hoc commands like `python3 -m json.tool` or manual validation. The run-linters script is the single source of truth for all linting and validation in this project.

### Running Code Quality Checks

After making any changes to the project, you MUST run the linter. After Dockerfile changes, also run the security scan:

```bash
# Run all linters (JSON validation, Dockerfile linting)
./.claude/bin/run-linters

# Run security vulnerability scan (builds the image automatically, run after Dockerfile changes)
./.claude/bin/run-security-scan
```

### Alternative Usage

```bash
# Lint with a specific Dockerfile path (JSON validation always runs)
./.claude/bin/run-linters path/to/Dockerfile

# Scan an existing Docker image
./.claude/bin/run-security-scan my-image:tag
```

### CI/CD Integration

These same tools run automatically in the CircleCI pipeline:

- The `scan` job runs both Trivy and Hadolint
- Builds will fail if critical vulnerabilities or linting errors are found
- The `.trivyignore.yml` file suppresses known acceptable warnings

### Development Workflow

1. Make your changes to the project files
2. Run the test suite: `./run-tests.sh`
3. Run all linters: `./.claude/bin/run-linters` (validates JSON, lints Dockerfile)
4. If Dockerfile was changed, run the security scan: `./.claude/bin/run-security-scan`
5. Address any issues found before committing

## Important Note About CLAUDE.md Files

This repository contains two CLAUDE.md files with different purposes:

1. **`/CLAUDE.md`** (this file) - Instructions for Claude Code when developing THIS Docker container
2. **`/assets/CLAUDE.md`** - Instructions that will be copied into the container for Claude Code to use when working on OTHER codebases

Do not add container-specific development instructions (like testing this container) to `assets/CLAUDE.md`.

## Claude Code Hooks

The container includes pre-configured Claude Code hooks that enforce deterministic behavior. These hooks are packaged into the final Docker image and affect Claude Code behavior when running inside the container on any codebase.

### Hook File Locations

| File | Purpose | Goes into Docker image? |
|------|---------|------------------------|
| `assets/.claude/settings.json` | Hook configuration (under `hooks` key) | **Yes** |
| `assets/.claude/hooks/` | Shell scripts for command-based hooks (if needed) | **Yes** |
| `.claude/settings.json` | This repo's dev environment only | No |

**Flow**: `assets/.claude/settings.json` → copied to `/workspace/.claude/settings.json` in container → active for all projects

### Current Hooks

| Hook | Type | Purpose |
|------|------|---------|
| **Stop** | Prompt-based | Reminds Claude to run tests/linters after making code changes |

### Stop Hook Behavior

The Stop hook runs when Claude finishes responding and:

1. **Checks for code changes**: Looks for Edit, Write, or MultiEdit tool usage in the session
2. **Checks for testing**: Looks for lint-runner or unit-test-runner sub-agent invocations
3. **Reminds if needed**: If code was changed but testing wasn't run, reminds Claude to use the sub-agents
4. **Prevents loops**: If already reminded once (stop_hook_active=true), allows stopping

This ensures Claude considers running the `run-tests` and `run-linters` helper scripts (via their respective sub-agents) after making changes.

### Hook Configuration Format

Hooks to be added to the final Docker Image are configured in `assets/.claude/settings.json` under the `hooks` key:

### Managing Hooks in This Repository

**Adding a new hook**:
1. Edit `assets/.claude/settings.json`
2. Add configuration under the appropriate event in the `hooks` object
3. For command-based hooks, create scripts in `assets/.claude/hooks/`
4. Run `./.claude/bin/run-linters` to validate JSON syntax
5. Test by building and running the Docker image

**Modifying an existing hook**:
1. Edit the hook configuration in `assets/.claude/settings.json`
2. Run `./.claude/bin/run-linters` to validate
3. Rebuild Docker image to test changes

**Testing hooks**:
1. Build the Docker image locally: `docker build -f Dockerfile -t claude-code-docker:local .`
2. Run the container and trigger the hook condition
3. Verify the expected behavior occurs

**Debugging hooks**:
- Check hook timeout isn't too short (default 30s)
- For prompt hooks, verify the prompt produces valid JSON
- For command hooks, test the script independently first

### Important Notes

- Hooks in `assets/.claude/settings.json` go into the **final Docker image**, not the current dev environment
- Changes require rebuilding the Docker image to take effect
- The `timeout` value (in seconds) prevents hooks from hanging indefinitely
- Prompt-based hooks use additional LLM tokens but provide intelligent analysis
- Always validate changes with `./.claude/bin/run-linters` before committing

**Reference**: [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)

## Playwright Integration

The container includes Playwright for browser automation testing. The setup includes:

- **Test Location**: Tests are stored in `/Users/claude-code/tests/playwright/` (same path in both container and host)
- **Auto-initialization**: The entrypoint script automatically creates the test directory structure and copies example files on first run
- **Host Access**: All test files and outputs are accessible from the host system for editing in IDEs
- **Path Consistency**: Paths are identical between host and container for clarity

### Volume Mounting

The container requires mounting the `/Users/claude-code` directory:

```bash
docker run -it --rm \
  -v $(pwd):/workspace/project \
  -v ~/.claude.json:/opt/user-claude/.claude.json \  # Your API key only
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.claude:/opt/user-claude/.claude \
  -v /Users/claude-code:/Users/claude-code \
  -e HOST_PWD=$(pwd) \
  -e HOST_USER=$(whoami) \
  wraithrmm/claude-code-docker:latest \
  /bin/bash
```

Note: MCP servers (including Playwright) are pre-configured in the container via `/workspace/.mcp.json`. Projects can add additional MCP servers via `.claude/.mcp.json`.

### Running Playwright Tests

From inside the container:

```bash
cd /Users/claude-code/tests
npm test                  # Run all tests
npm run test:headed       # Run tests with browser UI
npm run test:ui          # Open Playwright Test UI
npm run test:debug       # Debug tests
```

### File Structure

After first run, the following structure is created:

```bash
/Users/claude-code/tests/
├── package.json              # Playwright dependencies
├── playwright.config.ts      # Playwright configuration
└── playwright/
    └── example.spec.ts       # Example test file
```

All files are editable from the host system and changes are immediately reflected in the container.
