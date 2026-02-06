> Never install and run Claude Code locally on a device used to perform or manage company work.

This project allows the use of Claude Code on your repositories for AI-assisted development.

> All the usual stipulations regarding safe a secure use of AI and handling of PII apply to use of Claude Code regardless of its tooling status.
>
> Please ensure you are farmiliar with your AI Governance Policy before using this tooling.

A containerized environment that integrates [Claude Code](https://claude.ai/code) with a PHP/Apache infrastructure, enabling developers to run multiple Claude Code instances locally on any mapped codebase.

Before working with or on this, ensure you understand the appropriate AI usage guidelines for your organization.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Initial Setup](#initial-setup)
- [Running Claude Code on Your Project](#running-claude-code-on-your-project)
  - [Unattended Mode (claude-unsafe)](#unattended-mode-claude-unsafe)
- [Configuration Reference](#configuration-reference)
  - [Volume Mounts](#volume-mounts-explained)
  - [Environment Variables](#environment-variables-explained)
  - [Git Configuration](#optional-git-configuration-for-commits)
- [File Permissions and User Management](#file-permissions-and-user-management)
- [Running Multiple Instances](#running-multiple-instances)
- [Customizing Claude Code Behavior](#customizing-claude-code-behavior)
- [Playwright Integration](#playwright-integration)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

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

## Quick Start

Get Claude Code running on your project in 60 seconds:

1. **Prerequisites**: Docker installed, Claude subscription or API key

2. **Clone this repository**:

   ```bash
   git clone https://github.com/wraithrmm/claude-code-docker.git ~/claude-code-docker
   ```

3. **Add to your PATH** (so you can run `run-claude-code` from anywhere):

   Add the following to your shell profile (`~/.bashrc`, `~/.zshrc`, `~/.profile`, or equivalent):

   ```bash
   export PATH="$HOME/claude-code-docker/bin:$PATH"
   ```

   Then reload your shell:

   ```bash
   source ~/.bashrc   # or ~/.zshrc, ~/.profile, etc.
   ```

   > **Note:** The exact profile file depends on your shell and distribution. Common locations:
   > - **Bash**: `~/.bashrc` (interactive) or `~/.bash_profile` (login shells, macOS default)
   > - **Zsh**: `~/.zshrc` (macOS default since Catalina)
   > - **Fish**: `~/.config/fish/config.fish` (use `set -Ux fish_user_paths ~/claude-code-docker/bin $fish_user_paths`)
   >
   > If you prefer not to modify your PATH, you can always use the full path instead (e.g., `~/claude-code-docker/bin/run-claude-code`).

4. **Navigate to your project and launch**:

   ```bash
   cd /path/to/your/project
   run-claude-code
   ```

   The script mounts your current working directory into the container as the project workspace. It also automatically creates any missing dependencies (`~/.claude.json`, `~/.claude/`, workspace directory).

5. **Inside the container**:

   ```bash
   claude  # Start interactive session
   ```

   > **Unattended / "YOLO" mode:** The container also includes `claude-unsafe`, a helper
   > that runs Claude as a non-root user so that `--dangerously-skip-permissions` can be
   > used. **Read the [warnings below](#unattended-mode-claude-unsafe) before using it.**

See [Running Claude Code on Your Project](#running-claude-code-on-your-project) for all available options.

## Initial Setup

The `run-claude-code` launcher script automatically creates required directories. For authentication (first time only):

- **Claude subscription**: Follow the browser-based login flow when prompted
- **API key**: Enter your API key when prompted, or pre-create `~/.claude.json`:
  ```bash
  echo '{"apiKey": "your-api-key-here"}' > ~/.claude.json
  ```

## Running Claude Code on Your Project

1. **Navigate to your project directory and launch**

   From the root of whichever codebase you want to work on:

   ```bash
   cd /path/to/your/project
   run-claude-code
   ```

   If you haven't added the script to your PATH (see [Quick Start](#quick-start)), use the full path to where you cloned this repository:

   ```bash
   ~/claude-code-docker/bin/run-claude-code
   ```

   **Common options:**

   ```bash
   run-claude-code --host-network   # Use host networking (for local services)
   run-claude-code --no-docker-sock # Without Docker-in-Docker capability
   run-claude-code --dry-run        # Preview the docker command
   ```

2. **Inside the container, use Claude Code**

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

### Unattended Mode (claude-unsafe)

> **WARNING: USE AT YOUR OWN RISK.** The `claude-unsafe` helper enables
> `--dangerously-skip-permissions`, which allows Claude to execute **any** command
> without asking for confirmation. This includes destructive operations such as
> deleting files, overwriting code, running arbitrary shell commands, and making
> network requests. **You are solely responsible for any consequences.**

The container includes a `claude-unsafe` helper script for running Claude Code in
unattended ("YOLO") mode. This is intended **only** for automated pipelines, batch
processing, or situations where you have fully reviewed the prompt and accept all risk.

**How it works:** Claude Code requires a non-root user to enable
`--dangerously-skip-permissions`. The `claude-unsafe` script creates a dedicated
non-root user inside the container and runs Claude through it.

**Usage (inside the container):**

```bash
# Interactive unattended session
claude-unsafe --dangerously-skip-permissions

# Non-interactive with a prompt
claude-unsafe --dangerously-skip-permissions -p "refactor all tests to use vitest"
```

**Before using `claude-unsafe`, understand these risks:**

- Claude will execute **any** tool call (file writes, shell commands, etc.) without confirmation
- There is **no** undo — destructive actions happen immediately
- Your mounted project directory is fully writable by the AI
- If the Docker socket is mounted, Claude can execute arbitrary Docker commands on your host
- You should **always** have your code committed to version control before running unattended mode, so you can revert unwanted changes
- **Never** use this against a codebase containing secrets, credentials, or sensitive data that you would not want processed by an AI

**Recommended safeguards:**

1. Commit (or stash) all work before running
2. Use `--no-docker-sock` to prevent Docker-on-host access
3. Review the generated diff thoroughly after each run
4. Use in disposable/CI environments where damage is limited

## Configuration Reference

### Volume Mounts Explained

- `-v $(pwd):/workspace/project`: Mounts your current directory to the container's project workspace
- `-v ~/.claude.json:/opt/user-claude/.claude.json`: (Optional) Provides API key if using direct API access instead of subscription login
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

**Important Limitations:**

- This provides git **identity** (name, email, aliases) for commits
- This does **NOT** provide authentication credentials
- You **cannot** push, pull, or clone private repositories
- Git operations requiring authentication must be done on the host machine

The `:ro` flag mounts the config read-only for security.

**What this enables:**

- Local commits with your correct name/email
- Git aliases and preferences
- Git diff/log formatting preferences

**What this does NOT enable:**

- Push/pull to remote repositories
- Clone private repositories
- Any operation requiring SSH keys or tokens

## File Permissions and User Management

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

## Running Multiple Instances

To run Claude Code on multiple codebases simultaneously, open separate terminals:

**Terminal 1 - Project A:**

```bash
cd /path/to/project-a
run-claude-code
```

**Terminal 2 - Project B:**

```bash
cd /path/to/project-b
run-claude-code
```

Each instance runs independently with its own workspace mounted.

## Customizing Claude Code Behavior

Claude Code can be customized for your specific projects. All customizations go in your project's `.claude/` directory.

For full documentation with examples, see [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md).

### Project CLAUDE.md

Add a `CLAUDE.md` file to your project root with project-specific instructions, e.g:

```markdown
# Project Instructions

## Code Style
- Use TypeScript strict mode
- Follow ESLint rules

## Testing
Run tests with: `npm test`
```

### Custom Commands

Create slash commands in `.claude/commands/`:

```
your-project/.claude/commands/deploy.md
```

Usage: `/deploy`

### Custom Agents

Create specialized agents in `.claude/agents/`:

```
your-project/.claude/agents/security-reviewer.md
```

Agents use YAML frontmatter to define their behavior and are automatically invoked when their description matches the task.

### Project settings.json

Configure permissions in `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Bash(npm test:*)"],
    "deny": ["Read(**/.env*)"]
  }
}
```

### MCP Server Configuration

Add MCP servers in `.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "your-server": {
      "type": "stdio",
      "command": "your-command",
      "args": []
    }
  }
}
```

Project MCP servers are automatically merged with container defaults at startup.

## Playwright Integration

The container includes Playwright for browser automation testing with automatic setup and initialization.

### Features

- **Automatic Setup**: On first run, the container automatically creates the test directory structure and copies example files
- **Host Access**: All test files are stored at `/Users/claude-code/tests/` (same path in both container and host)
- **Pre-configured**: Includes TypeScript support and all Playwright browsers installed

### Using Playwright

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

### Important Notes

- The `/Users/claude-code/` directory must be mounted when running the container
- Existing files are never overwritten, preserving your custom tests
- Test results and reports are accessible from both host and container

## Best Practices

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

For information on developing and contributing to this Docker image, see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

This includes:
- Building the image locally
- Running tests
- Code quality checks (linting, security scanning)
- Development workflow

## License

This project is licensed under the **PolyForm Shield License 1.0.0**.

### What This Means

**You CAN:**
- Use this software for free for any purpose
- Modify the software for your own use
- Distribute copies of the software
- Use this software commercially to build your own solutions

**You CANNOT:**
- Create a competing product or service using this software
- Rebrand and sell this software as your own product
- Offer this software as a hosted service that competes with the original

### License Details

The PolyForm Shield License allows free use while preventing competitors from simply repackaging and selling the software. If you're using this tool to develop your own applications, you're free to do so. If you want to create a competing "Claude Code Docker" service, you'll need a separate commercial license.

Full license text: [LICENSE](LICENSE)
License information: https://polyformproject.org/licenses/shield/1.0.0/

```
Required Notice: Copyright (c) 2025-present Richard Mann
```
