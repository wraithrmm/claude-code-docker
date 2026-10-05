# Customizing Claude Code for Your Projects

This guide covers how to customize Claude Code behavior for your specific codebases. All customizations are placed in your project's `.claude/` directory.

## Table of Contents

- [Project CLAUDE.md Files](#project-claudemd-files)
- [Custom Commands](#custom-commands)
- [Custom Agents](#custom-agents)
- [Project settings.json](#project-settingsjson)
- [MCP Server Configuration](#mcp-server-configuration)
- [Custom Skills](#custom-skills)
- [Workflow Plugins](#workflow-plugins)

---

## Project CLAUDE.md Files

Your project can include a `CLAUDE.md` file to provide project-specific instructions that Claude Code will follow when working on your codebase.

### Location

Place the file at your project root:

```
your-project/
├── CLAUDE.md              # Project instructions for Claude
└── ...
```

### What to Include

A project CLAUDE.md typically contains:

- **Project context**: Architecture overview, tech stack
- **Code style guidelines**: Formatting, naming conventions
- **Testing instructions**: How to run tests, expected patterns
- **Build commands**: How to build/compile the project
- **Important notes**: Things Claude should or shouldn't do

### Example

```markdown
# Project Instructions for Claude

## Overview
This is a React/TypeScript web application using Redux for state management.

## Code Style
- Use functional components with hooks
- Prefer named exports over default exports
- Run prettier before committing

## Testing
Run tests with: `npm test`
Tests are in `__tests__/` directories alongside source files.

## Build Commands
- Development: `npm run dev`
- Production: `npm run build`

## Important Notes
- Never modify files in `/generated/` directory
- Always run linting after changes: `npm run lint`
```

---

## Custom Commands

Commands are slash-invocable actions defined as Markdown files. They extend Claude Code's capabilities with project-specific workflows.

### Location

```
your-project/
└── .claude/
    └── commands/
        └── your-command.md
```

### File Format

Commands are simple Markdown files. The filename (without `.md`) becomes the command name.

```markdown
# Deploy to Staging

## Goals
Deploy the application to the staging environment.

## Workflow
1. Run all tests first
2. Build the production bundle
3. Deploy using: `./scripts/deploy-staging.sh`
4. Verify deployment at https://staging.example.com
```

### Using Commands

Inside Claude Code, invoke with a slash:

```
/deploy
```

### Namespacing Commands

To avoid conflicts with built-in commands, use subdirectories:

```
your-project/
└── .claude/
    └── commands/
        └── myproject/
            ├── deploy.md        # Usage: /myproject/deploy
            └── db-migrate.md    # Usage: /myproject/db-migrate
```

### Built-in Commands Reference

Most built-in commands are skills from the `workflow` plugin (see [Workflow Plugins](#workflow-plugins)). Each is invoked by its bare name unless your project defines a skill with the same name; then use `/workflow:<name>`.

| Command | Description |
|---------|-------------|
| `/hello` | Initialize workspace and verify environment |
| `/init-playground` | Set up the ai-playground and show its status |
| `/create-project <name>` | Create a new project plan structure |
| `/continue-project <name>` | Resume work on an existing project |
| `/list-projects` | Show all projects in ai-playground |
| `/create-task <name>` | Create a new task for tracking |
| `/list-tasks` | Show all tasks grouped by status |
| `/move-task <name> <status>` | Move task to different status |
| `/create-project-task <project> <task>` | Create a task within a project |
| `/list-project-tasks <project>` | List a project's tasks by status |
| `/move-project-task <project> <task> <status>` | Move a project task to a different status |
| `/add-acceptance-criteria <feature> <use-case>` | Add acceptance criteria to a feature, implement and test |
| `/toggle-branch-beacon` | Hide or show the branch chip (`branch-beacon` plugin) |
| `/test-and-fix` | Run tests and iteratively fix failures (baked into the image) |

---

## Custom Agents

Agents are specialized Claude Code personas with specific expertise. They're automatically invoked when their description matches the current task.

### Location

```
your-project/
└── .claude/
    └── agents/
        └── your-agent.md
```

### File Format

Agent files use YAML frontmatter followed by Markdown instructions:

```markdown
---
name: security-reviewer
description: Use this agent for security code reviews focusing on OWASP vulnerabilities and authentication patterns.
model: inherit
color: red
---

You are a security-focused code reviewer. Your role is to identify potential security vulnerabilities in code changes.

## Core Responsibilities
1. Review code for common vulnerabilities (SQL injection, XSS, CSRF)
2. Check authentication and authorization patterns
3. Identify insecure data handling

## Output Format
Provide findings in severity-ordered list with specific file/line references.
```

### Frontmatter Options

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Identifier for the agent |
| `description` | Yes | When to invoke this agent (Claude uses this to decide) |
| `model` | No | `inherit`, `sonnet`, or `opus` (default: inherit) |
| `color` | No | Terminal color: `yellow`, `red`, `green`, `blue` |

### Built-in Agents

The `workflow` plugin provides these agents. Plugin agents are only reachable with the plugin prefix, for example `Task(subagent_type="workflow:lint-runner", ...)`:

| Agent | Purpose |
|-------|---------|
| `workflow:playwright-visual-tester` | Visual verification, screenshots, UI testing |
| `workflow:lint-runner` | Code quality checks and linting |
| `workflow:unit-test-runner` | Running and analyzing test results |

### Example: Database Migration Agent

```markdown
---
name: db-migrator
description: Use this agent when creating or reviewing database migrations, schema changes, or data migrations.
model: inherit
color: blue
---

You are a database migration specialist. Focus on safe, reversible migrations.

## Responsibilities
1. Create migration files following project conventions
2. Ensure migrations are reversible (up/down methods)
3. Check for data integrity issues
4. Validate foreign key constraints

## Before Creating Migrations
- Check existing schema in `database/schema.sql`
- Review recent migrations for naming patterns
- Verify no pending migrations exist
```

---

## Project settings.json

Configure Claude Code permissions and environment variables for your project.

### Location

```
your-project/
└── .claude/
    └── settings.json
```

### Schema

```json
{
  "permissions": {
    "allow": [
      "permission-pattern"
    ],
    "deny": [
      "permission-pattern"
    ]
  },
  "env": {
    "VARIABLE_NAME": "value"
  }
}
```

### Permission Pattern Syntax

| Pattern | Description |
|---------|-------------|
| `Read(path-glob)` | Allow/deny reading files |
| `Write(path-glob)` | Allow/deny writing files |
| `Edit(path-glob)` | Allow/deny editing files |
| `Bash(command:args)` | Allow/deny specific bash commands |

### Path Glob Patterns

- `**` - Match any directory depth
- `*` - Match any characters in a single segment
- Paths are relative to project root

### Example Configuration

```json
{
  "permissions": {
    "allow": [
      "Read(/workspace/project/**)",
      "Write(/workspace/project/**)",
      "Edit(/workspace/project/**)",
      "Bash(npm test:*)",
      "Bash(npm run:*)",
      "Bash(./scripts/*.sh:*)"
    ],
    "deny": [
      "Read(**/.env)",
      "Read(**/.env*)",
      "Read(**/secrets/**)",
      "Read(**/*credentials*)",
      "Write(**/node_modules/**)",
      "Write(**/package-lock.json)",
      "Bash(rm -rf:*)"
    ]
  },
  "env": {
    "DISABLE_TELEMETRY": "1",
    "NODE_ENV": "development"
  }
}
```

### Common Permission Patterns

**Allow project scripts:**
```json
"Bash(./scripts/*.sh:*)"
```

**Allow npm commands:**
```json
"Bash(npm:*)"
```

**Block environment files:**
```json
"Read(**/.env*)"
```

**Block specific directories:**
```json
"Write(**/vendor/**)"
```

---

## MCP Server Configuration

Add Model Context Protocol (MCP) servers for extended capabilities like external APIs, databases, or custom tools.

### Location

```
your-project/
└── .claude/
    └── .mcp.json
```

**Note:** The file must be in `.claude/.mcp.json`, not the project root.

### File Format

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### How MCP Merging Works

1. Container has default MCP servers in `/workspace/.mcp.json`
2. Your project's `.claude/.mcp.json` is merged at startup
3. Project servers take precedence if names conflict
4. Invalid JSON files are handled gracefully

### Example: AWS Documentation Server

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
    }
  }
}
```

### Example: Terraform Server

```json
{
  "mcpServers": {
    "terraform": {
      "type": "stdio",
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server"],
      "env": {}
    }
  }
}
```

---

## Custom Skills

Skills are reusable instructions Claude loads when a task matches their description. They replace the PRP templates used by earlier versions of this container: put reusable implementation patterns (required information, workflow steps, file map, acceptance criteria) in a skill.

### Location

```
your-project/
└── .claude/
    └── skills/
        └── api-endpoint/
            └── SKILL.md
```

### File Format

```markdown
---
name: api-endpoint
description: Create a new REST API endpoint with validation and tests. Use when adding or changing an API route.
---

# REST API Endpoint

## Required Information
- Endpoint path, HTTP method, request/response schema, authentication requirements

## Workflow Steps
1. Create route handler in `src/routes/`
2. Add input validation schema
3. Implement business logic and error handling
4. Write unit tests
5. Update API documentation

## Acceptance Criteria
- [ ] Route responds with correct status codes
- [ ] Input validation rejects invalid data
- [ ] Unit tests pass
```

A project skill with the same name as a `workflow` plugin skill takes the bare name; the plugin's version stays reachable as `/workflow:<name>`.

---

## Workflow Plugins

The project and task workflow commands, their helper scripts and the built-in agents come from two Claude Code plugins in the `wraithrmm` marketplace, hosted at [wraithrmm/claude-workflow](https://github.com/wraithrmm/claude-workflow):

- **`workflow`**: PRP project and task workflow skills, helper scripts, the `workflow:*` agents and the `workflow-guide` skill with the full process and file formats.
- **`branch-beacon`**: shows the checked-out git branch and repo name as a coloured chip above the prompt. `/toggle-branch-beacon` hides or shows it.

The container fetches the latest version of the plugins on every start (falling back to a copy baked into the image), so updates arrive on the next container start. See the [README](../README.md#workflow-plugins) for the environment variables that control this.

The workflow scripts are no longer in `/workspace/.claude/bin/`; inside the container they live at `/opt/claude-plugins/current/plugins/workflow/scripts/` and are run through their skills.

### Without Docker

```bash
claude plugin marketplace add wraithrmm/claude-workflow
claude plugin install workflow@wraithrmm
claude plugin install branch-beacon@wraithrmm
```

Do not also install them into a host `~/.claude` that you mount into the container; they may load twice.

---

## Directory Structure Summary

Complete `.claude/` directory structure for a fully customized project:

```
your-project/
├── CLAUDE.md                    # Project instructions
└── .claude/
    ├── settings.json            # Permissions and environment
    ├── .mcp.json                 # MCP server configuration
    ├── commands/
    │   ├── deploy.md            # /deploy command
    │   └── myproject/
    │       └── lint-all.md      # /myproject/lint-all command
    ├── agents/
    │   └── security-reviewer.md # Security review agent
    └── skills/
        └── api-endpoint/
            └── SKILL.md         # API endpoint skill
```
