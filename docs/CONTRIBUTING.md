# Contributing to Claude Code Docker

This document covers development and contribution to the Docker image itself. For **using** the image with your projects, see the main [README.md](../README.md).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building the Image](#building-the-image)
- [Modifying the Image](#modifying-the-image)
- [Testing the Entrypoint Script](#testing-the-entrypoint-script)
- [Code Quality Checks](#code-quality-checks)
- [Docker Compose Development](#docker-compose-development)
- [Submitting Changes](#submitting-changes)

## Prerequisites

- Docker installed on your development machine
- Docker Hub account (for pulling/pushing images)
- Docker CLI configured with your credentials

## Building the Image

1. **Clone the repository**

   ```bash
   git clone https://github.com/wraithrmm/claude-code-docker.git
   cd claude-code-docker
   ```

2. **Build the Docker image**

   ```bash
   docker build -f Dockerfile -t claude-code-docker:local . --build-arg TAGGED_VERSION=local
   ```

   Optional build arguments:

   - `PHP_VERSION`: Specify PHP version (default: 8.3)
   - `OS_RELEASE`: Specify OS release (default: -bookworm)
   - `TAGGED_VERSION`: Version tag for the image
   - `CACHE_BUST`: Force rebuild without cache

## Modifying the Image

When making changes to the Docker image:

1. **Update the Dockerfile** with your modifications
2. **Test locally** using the build command above
3. **Update version tags** appropriately
4. **Document changes** in commit messages
5. **Update the README** if adding new features or changing usage

## Testing the Entrypoint Script

The repository includes a comprehensive test suite for the entrypoint script using BATS (Bash Automated Testing System).

### Test Structure

- `tests/` - Test directory
  - `entrypoint.bats` - Main test file containing all test cases
  - `test_helper.bash` - Utility functions for testing
- `run-tests.sh` - Convenience script to run tests locally

### Running Tests Locally

```bash
# Install BATS (one-time setup)
npm install -g bats

# Run all tests
./run-tests.sh

# Run specific tests
bats tests/entrypoint.bats --filter "test name"
```

### CI/CD Integration

Tests are automatically run in CircleCI before building the Docker image. The build will fail if any tests fail.

### Writing New Tests

When adding new functionality to the entrypoint script, please add corresponding tests to ensure the behavior is verified.

## Code Quality Checks

**Important:** After making any changes to the Dockerfile, you must run both security scanning and linting tools before committing.

The repository includes Docker-based scanning tools that mirror the CircleCI pipeline checks. These tools require no local installation - everything runs in Docker containers.

### Available Tools

1. **Dockerfile Linter** - Uses Hadolint to check Dockerfile best practices
2. **Security Scanner** - Uses Trivy to scan for vulnerabilities in the built image

### Running Quality Checks

```bash
# Run Dockerfile linter
./.claude/bin/run-linters

# Run security vulnerability scan (builds the image automatically)
./.claude/bin/run-security-scan

# Or scan an existing image
./.claude/bin/run-security-scan claude-code-docker:latest
```

### Understanding the Output

- **Hadolint** will report warnings about best practices (e.g., pinning versions, consolidating RUN commands)
- **Trivy** will scan for known vulnerabilities in packages and dependencies
- The `.trivyignore.yml` file suppresses known acceptable warnings (like DS002 for root user)

### Development Workflow

1. Make your changes to the Dockerfile
2. Run the test suite: `./run-tests.sh`
3. Run the linter: `./.claude/bin/run-linters`
4. Run the security scan: `./.claude/bin/run-security-scan`
5. Address any issues found before committing
6. Commit your changes

## Docker Compose Development

For easier development, use Docker Compose:

```bash
docker-compose build
docker-compose run --rm claude-code
```

## Submitting Changes

When contributing to this Docker image:

1. Follow established coding standards
2. Test changes thoroughly before submitting
3. Update documentation as needed
4. Submit changes through the standard PR process
