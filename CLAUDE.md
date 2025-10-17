# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a Docker prototype for integrating Claude Code into the Aurora Commerce infrastructure. The project creates a containerized environment that combines a PHP/Apache base image with Claude Code installation with the objective of allow staff to run Claude Code in a Docker container so that they can run multiple instances locally, at once, on any mapped codebase.

## Architecture

- **Base Image**: Uses Aurora Commerce's custom PHP/Apache base image from ECR (`571637302133.dkr.ecr.eu-west-1.amazonaws.com/docker-base-php-apache`)
- **Runtime Environment**: Node.js LTS installed alongside PHP/Apache for Claude Code functionality
- **Working Directory**: `/workspace` is the designated directory for Claude Code projects within the container
- **Service Identity**: Tagged as `claudecode` service in Aurora Commerce's labeling system

## Docker Commands

Build the Docker image:

```bash
docker build -f Dockerfile -t ac-ai-claudecode-local . --build-arg TAGGED_VERSION=localdev
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
  ac-ai-claudecode-local:localdev \
  /bin/bash
```

Note: The container includes pre-configured MCP servers (like Playwright) in `/workspace/.mcp.json`. If your project has a `.claude/.mcp.json` file, it will be automatically merged with the container's MCP configuration on startup, with project servers taking precedence.

## Security Scanning

The repository includes `.trivyignore` to suppress base image security warnings (DS002) since the Aurora Commerce base image runs as root by design.

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

1. **Dockerfile Linter** (`run-linters`) - Uses Hadolint to check Dockerfile best practices
2. **Security Scanner** (`run-security-scan`) - Uses Trivy to scan for vulnerabilities

### Running Code Quality Checks

After making any changes to the Dockerfile, you MUST run both tools:

```bash
# Run Dockerfile linter
./.claude/bin/run-linters

# Run security vulnerability scan (builds the image automatically)
./.claude/bin/run-security-scan
```

### Alternative Usage

```bash
# Lint a specific Dockerfile
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

1. Make your changes to the Dockerfile
2. Run the test suite: `./run-tests.sh`
3. Run the linter: `./.claude/bin/run-linters`
4. Run the security scan: `./.claude/bin/run-security-scan`
5. Address any issues found before committing

## Important Note About CLAUDE.md Files

This repository contains two CLAUDE.md files with different purposes:

1. **`/CLAUDE.md`** (this file) - Instructions for Claude Code when developing THIS Docker container
2. **`/assets/CLAUDE.md`** - Instructions that will be copied into the container for Claude Code to use when working on OTHER codebases

Do not add container-specific development instructions (like testing this container) to `assets/CLAUDE.md`.

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
  ac-ai-claudecode-local \
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
