---
confluence:
  page_id: 2072870914
  space: "Polaris"
  title: "Claude Code (Docker Image)"
  labels: ["automation", "dev-tooling", "documentation"]
  update_mode: "replace"
---

> Never install and run Claude Code locally on a device used to perform or manage company work.

This project allows the use of Claude Code on your repositories for AI-assisted development.

> All the usual stipulations regarding safe a secure use of IA and handling of PII apply to use of CLaude Code regardless of its tooling status.
>
> Please ensure you are farmiliar with our AI Governance Policy before using this tooling.

A containerized environment that integrates [Claude Code](https://claude.ai/code) with a PHP/Apache infrastructure, enabling developers to run multiple Claude Code instances locally on any mapped codebase.

Before working with or on this, ensure you understand the appropriate AI usage guidelines for your organization.

## Table of Contents

- [Overview](#overview)
- [Developing the Claude Code Docker Image Itself](#developing-the-claude-code-docker-image-itself)
- [Using the Claude Code Image to Develop on a Codebase](#using-the-claude-code-image-to-develop-on-a-codebase)
- [Security Considerations](#security-considerations)

## Overview

This Docker image combines a custom PHP/Apache base image with Claude Code, providing a seamless development environment for AI-assisted coding. The container includes:

- PHP 8.3 with Apache web server
- Node.js LTS for Claude Code runtime
- Claude Code CLI installed globally with auto-update capability
- Docker CE (version 24+) and docker-compose for running containers and tests
- Playwright with TypeScript support for browser automation testing
- Workspace directory at `/workspace` for project files
- Automatic user detection and permission management
- Secure user switching with gosu for proper file ownership

## Developing the Claude Code Docker Image Itself

### Prerequisites

- Docker installed on your development machine
- Docker Hub account (for pulling/pushing images)
- Docker CLI configured with your credentials

### Building the Image

1. **Clone the repository**

   ```bash
   git clone [repository-url]
   cd ac-ai-claudecode
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

### Modifying the Image

When making changes to the Docker image:

1. **Update the Dockerfile** with your modifications
2. **Test locally** using the build command above
3. **Update version tags** appropriately
4. **Document changes** in commit messages
5. **Update this README** if adding new features or changing usage

### Testing the Entrypoint Script

The repository includes a comprehensive test suite for the entrypoint script using BATS (Bash Automated Testing System).

#### Test Structure

- `tests/` - Test directory
  - `entrypoint.bats` - Main test file containing all test cases
  - `test_helper.bash` - Utility functions for testing
- `run-tests.sh` - Convenience script to run tests locally

#### Running Tests Locally

```bash
# Install BATS (one-time setup)
npm install -g bats

# Run all tests
./run-tests.sh

# Run specific tests
bats tests/entrypoint.bats --filter "test name"
```

#### CI/CD Integration

Tests are automatically run in CircleCI before building the Docker image. The build will fail if any tests fail.

#### Writing New Tests

When adding new functionality to the entrypoint script, please add corresponding tests to ensure the behavior is verified.

### Code Quality Checks

**Important:** After making any changes to the Dockerfile, you must run both security scanning and linting tools before committing.

The repository includes Docker-based scanning tools that mirror the CircleCI pipeline checks. These tools require no local installation - everything runs in Docker containers.

#### Available Tools

1. **Dockerfile Linter** - Uses Hadolint to check Dockerfile best practices
2. **Security Scanner** - Uses Trivy to scan for vulnerabilities in the built image

#### Running Quality Checks

```bash
# Run Dockerfile linter
./.claude/bin/run-linters

# Run security vulnerability scan (builds the image automatically)
./.claude/bin/run-security-scan

# Or scan an existing image
./.claude/bin/run-security-scan ac-ai-claudecode-local:latest
```

#### Development Workflow

1. Make your changes to the Dockerfile
2. Run the test suite: `./run-tests.sh`
3. Run the linter: `./.claude/bin/run-linters`
4. Run the security scan: `./.claude/bin/run-security-scan`
5. Address any issues found before committing
6. Commit your changes

#### Understanding the Output

- **Hadolint** will report warnings about best practices (e.g., pinning versions, consolidating RUN commands)
- **Trivy** will scan for known vulnerabilities in packages and dependencies
- The `.trivyignore.yml` file suppresses known acceptable warnings (like DS002 for root user)

### Docker Compose Development

For easier development, use Docker Compose:

```bash
docker-compose build
docker-compose run --rm claude-code
```

## Using the Claude Code Image to Develop on a Codebase

### Initial Setup

1. **Obtain Your Claude Code Enabled Subscription**

2. **Configure Claude Code** (first-time setup)

   ```bash
   # Create config directory
   mkdir -p ~/.claude

   # Create config file with your API key
   echo '{"apiKey": "your-api-key-here"}' > ~/.claude.json
   ```

### Running Claude Code on Your Project

1. **Navigate to your project directory**

   ```bash
   cd /path/to/your/project
   ```

2. **Run the container with your codebase mounted**

   ```bash
   docker run -it --rm \
     -v $(pwd):/workspace/project \
     -v ~/.claude.json:/opt/user-claude/.claude.json \
     -v ~/.claude:/opt/user-claude/.claude \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v /Users/claude-code/:/Users/claude-code/ \
     -e HOST_PWD=$(pwd) \
     -e HOST_USER=$(whoami) \
     wraithrmm/claude-code-docker:latest \
     /bin/bash
   ```

   **To run as root (when needed):**

   ```bash
   docker run -it --rm \
     -v $(pwd):/workspace/project \
     -v ~/.claude.json:/opt/user-claude/.claude.json \
     -v ~/.claude:/opt/user-claude/.claude \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v /Users/claude-code/:/Users/claude-code/ \
     -e HOST_PWD=$(pwd) \
     -e HOST_USER=$(whoami) \
     -e RUN_AS_ROOT=true \
     wraithrmm/claude-code-docker:latest \
     /bin/bash
   ```

3. **Inside the container, use Claude Code**

   ```bash
   # Verify Claude Code is available
   claude --version

   # Verify Docker and docker-compose are available
   docker --version
   docker compose version

   # Start an interactive session
   claude

   # Or run a specific command
   claude "explain the purpose of this codebase"
   ```

### Volume Mounts Explained

- `-v $(pwd):/workspace/project`: Mounts your current directory to the container's project workspace
- `-v ~/.claude.json:/opt/user-claude/.claude.json`: Provides API key configuration (mounted to avoid permission conflicts)
- `-v ~/.claude:/opt/user-claude/.claude`: Persists Claude Code settings and cache (mounted to avoid permission conflicts)
- `-v /var/run/docker.sock:/var/run/docker.sock`: Provides access to the running docker sock for running containers from within this container
- `-v /Users/claude-code/:/Users/claude-code/`: Provides a consistent path for file exchange and Playwright tests between host and container

### Environment Variables Explained

- `-e HOST_PWD=$(pwd)`: Allows docker mount the CWD from within the container for things like Unit Test execution
- `-e HOST_USER=$(whoami)`: Provides the host user identity to the container for proper ownership and permissions
- `-e RUN_AS_ROOT=true`: Optional - Forces container to run as root instead of creating a matching user

### Optional: Git Configuration for Commits

To use your host git configuration for **local commits only**, add this volume mount:

```bash
-v ~/.gitconfig:/opt/user-gitconfig/.gitconfig:ro \
```

**⚠️ Important Limitations:**

- This provides git **identity** (name, email, aliases) for commits
- This does **NOT** provide authentication credentials
- You **cannot** push, pull, or clone private repositories
- Git operations requiring authentication must be done on the host machine

The `:ro` flag mounts the config read-only for security.

**What this enables:**

- ✅ Local commits with your correct name/email
- ✅ Git aliases and preferences
- ✅ Git diff/log formatting preferences

**What this does NOT enable:**

- ❌ Push/pull to remote repositories
- ❌ Clone private repositories
- ❌ Any operation requiring SSH keys or tokens

### File Permissions and User Management

By default, the container automatically:

- **Auto-detects your host user's UID/GID** from the mounted `/workspace/project` directory
- **Creates a matching user** inside the container with the same username as HOST_USER
- **Switches to that user** so files are created with proper ownership
- **Updates Claude Code** to the latest version on every startup
- **Provides Docker access** by adding the user to the docker group

**When to use RUN_AS_ROOT=true:**

- You need root privileges inside the container
- Debugging permission issues
- Running administrative tasks

**File ownership benefits:**

- Files created inside the container are owned by your host user
- No more `sudo chown` needed after container operations
- Seamless file editing between host and container

### Running Multiple Instances

To run Claude Code on multiple codebases simultaneously:

1. **Terminal 1 - Project A**

   ```bash
   cd /path/to/project-a
   docker run -it --rm --name claude-project-a \
     -v $(pwd):/workspace/project \
     -v ~/.claude.json:/opt/user-claude/.claude.json \
     -v ~/.claude:/opt/user-claude/.claude \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v /Users/claude-code/:/Users/claude-code/ \
     -e HOST_PWD=$(pwd) \
     -e HOST_USER=$(whoami) \
     wraithrmm/claude-code-docker:latest \
     /bin/bash
   ```

2. **Terminal 2 - Project B**

   ```bash
   cd /path/to/project-b
   docker run -it --rm --name claude-project-b \
     -v $(pwd):/workspace/project \
     -v ~/.claude.json:/opt/user-claude/.claude.json \
     -v ~/.claude:/opt/user-claude/.claude \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v /Users/claude-code/:/Users/claude-code/ \
     -e HOST_PWD=$(pwd) \
     -e HOST_USER=$(whoami) \
     wraithrmm/claude-code-docker:latest \
     /bin/bash
   ```

### Custom Commands

Claude Code supports custom commands that can be added at two levels:

#### 1. Repository-Level Commands (Built into the Image)

Commands that should be available in ALL Claude Code containers are placed in this repository:

```text
ac-ai-claudecode/
└── assets/
    └── .claude/
        └── commands/
            ├── test-and-fix.md      # Example built-in command
            └── your-command.md      # Add new built-in commands here
```

These commands are built into the Docker image and available to all users.

#### 2. Project-Level Commands (Per Codebase)

Commands specific to a particular project are placed in that project's repository. To avoid command name conflicts, it's recommended to use subdirectories:

```text
your-project/
└── .claude/
    └── commands/
        └── yourprojectname/     # Use a subdirectory to namespace your commands
            ├── deploy.md        # Project-specific command: /yourprojectname/deploy
            └── custom-lint.md   # Another command: /yourprojectname/custom-lint
```

When you run the Claude Code container, these project commands are automatically detected and made available alongside the built-in commands.

#### How Commands are Combined

When the container starts:

1. Built-in commands from `assets/.claude/commands/` are already in `/workspace/.claude/commands/`
2. The entrypoint script checks for `/workspace/project/.claude/commands/`
3. If found, project commands are copied to `/workspace/.claude/commands/`
4. Both sets of commands are now available in Claude Code

#### Using Commands

Inside the Claude Code session, you can use any available command:

```bash
# Built-in command
/test-and-fix

# Project-specific command (with namespace)
/deploy
/custom-lint
```

### MCP Server Configuration

The container includes pre-configured MCP servers (like Playwright). Projects can add their own MCP servers by creating a `.mcp.json` file in the project's `.claude` directory.

#### How MCP Configuration Works

1. Container provides default MCP servers in `/workspace/.mcp.json`
2. Project can define additional servers in `/workspace/project/.claude/.mcp.json`
3. During startup, configurations are automatically merged
4. Project servers take precedence if names conflict
5. Invalid JSON files are handled gracefully - valid configuration is preserved

#### Example Project MCP Configuration

Create a `.mcp.json` file in your project's `.claude` directory:

```json
{
  "mcpServers": {
    "aws-docs": {
      "type": "stdio",
      "command": "uvx",
      "args": ["awslabs.aws-documentation-mcp-server@latest"],
      "env": {
        "AWS_DOCUMENTATION_PARTITION": "aws",
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    },
    "aws-knowledge": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "mcp-proxy",
        "--transport",
        "streamablehttp",
        "https://knowledge-mcp.global.api.aws"
      ],
      "env": {}
    },
    "terraform": {
      "type": "stdio",
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server"],
      "env": {}
    }
  }
}
```

#### MCP Configuration Merging Rules

If either configuration file contains invalid JSON, the system will:

- Use the valid configuration if only one is valid
- Keep the original container configuration if both are invalid
- Merge both configurations if both are valid (project servers override container servers with same names)

**Note**: Only `.claude/.mcp.json` is checked in the project directory. Any `.mcp.json` file in the project root will be ignored.

### Playwright Integration

The container includes Playwright for browser automation testing with automatic setup and initialization.

#### Features

- **Automatic Setup**: On first run, the container automatically creates the test directory structure and copies example files
- **Host Access**: All test files are stored at `/Users/claude-code/tests/` (same path in both container and host)
- **Pre-configured**: Includes TypeScript support and all Playwright browsers installed

#### Using Playwright

1. **First Run**: The container automatically initializes the test structure:

   ```text
   /Users/claude-code/tests/
   ├── package.json              # Playwright dependencies
   ├── playwright.config.ts      # Playwright configuration
   └── playwright/
       └── example.spec.ts       # Example test file
   ```

2. **Running Tests**: From inside the container:

   ```bash
   cd /Users/claude-code/tests
   npm test                  # Run all tests
   npm run test:headed       # Run tests with browser UI
   npm run test:ui          # Open Playwright Test UI
   npm run test:debug       # Debug tests
   ```

3. **Writing Tests**: All test files in `/Users/claude-code/tests/playwright/` are accessible from your host IDE for editing

#### Important Notes

- The `/Users/claude-code/` directory must be mounted when running the container
- Existing files are never overwritten, preserving your custom tests
- Test results and reports are accessible from both host and container

### Best Practices

1. **Version Control**: Ensure your code is committed before running Claude Code modifications
2. **Code Review**: Always review Claude Code's suggestions before applying them
3. **Workspace Organization**: Keep your `/workspace` directory organized within the container
4. **Resource Management**: Monitor container resource usage when running multiple instances
5. **Custom Commands**:
   - Document your custom commands clearly with examples and expected inputs
   - Use project name subdirectories to avoid command naming conflicts
   - Follow consistent naming conventions for commands

## Security Considerations

Ensure you understand and follow appropriate AI usage guidelines and security practices when using Claude Code.

### Base Image Security

- The base image starts as root but automatically switches to host user for operations
- By default, files are created with host user ownership for security
- Use `RUN_AS_ROOT=true` only when root privileges are specifically needed
- `.trivyignore` suppresses DS002 warnings about root user in base image
- All security patches are handled in the base image updates

### API Key Security

- Always abide by security best practices and your organization's AI usage policies
- Store API keys in secure locations only that are not exposed to the AI
- Use environment variables or mounted config files
- Rotate API keys regularly

### Container Security

- Run containers with minimal required privileges
- Avoid mounting sensitive directories unnecessarily
- Clean up containers and images regularly

### Getting Help

- Check Claude Code documentation: <https://docs.anthropic.com/en/docs/claude-code>
- Contact your DevOps team for base image issues

## Contributing

When contributing to this Docker image:

1. Follow established coding standards
2. Test changes thoroughly before submitting
3. Update documentation as needed
4. Submit changes through the standard PR process

## License

This project is provided under standard open source licensing terms.
