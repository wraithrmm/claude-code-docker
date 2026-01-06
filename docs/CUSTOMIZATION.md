# Customizing Claude Code for Your Projects

This guide covers how to customize Claude Code behavior for your specific codebases. All customizations are placed in your project's `.claude/` directory.

## Table of Contents

- [Project CLAUDE.md Files](#project-claudemd-files)
- [Custom Commands](#custom-commands)
- [Custom Agents](#custom-agents)
- [Project settings.json](#project-settingsjson)
- [MCP Server Configuration](#mcp-server-configuration)
- [PRP Templates](#prp-templates)

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

The container includes these commands by default:

| Command | Description |
|---------|-------------|
| `/hello` | Initialize workspace and verify environment |
| `/test-and-fix` | Run tests and iteratively fix failures |
| `/create-project` | Create a new project plan structure |
| `/continue-project <name>` | Resume work on an existing project |
| `/list-projects` | Show all projects in ai-playground |
| `/create-task <name>` | Create a new task for tracking |
| `/list-tasks` | Show all tasks grouped by status |
| `/move-task <name> <status>` | Move task to different status |

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

The container includes:

| Agent | Purpose |
|-------|---------|
| `playwright-visual-tester` | Visual verification, screenshots, UI testing |
| `lint-runner` | Code quality checks and linting |
| `unit-test-runner` | Running and analyzing test results |

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

## PRP Templates

PRP (Project Requirement Plan) Templates provide reusable patterns for common development tasks.

### Location

```
your-project/
└── .claude/
    └── prp-templates/
        └── your-template.md
```

### Template Structure

```markdown
# PRP Template: [Template Name]

## Purpose
Brief description of what this template is for.

## Required Information
Information Claude must gather before proceeding:
- [ ] Required field 1
- [ ] Required field 2

## Workflow Steps
1. Step one
2. Step two
3. Step three

## File Map
### New Files
- `path/to/file.ext` - Purpose

### Modified Files
- `path/to/existing.ext` - Changes

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

### Example: API Endpoint Template

```markdown
# PRP Template: REST API Endpoint

## Purpose
Guide for creating new REST API endpoints with proper structure and testing.

## Required Information
- [ ] Endpoint path (e.g., /api/users)
- [ ] HTTP method (GET, POST, PUT, DELETE)
- [ ] Request/response schema
- [ ] Authentication requirements

## Workflow Steps
1. Create route handler in `src/routes/`
2. Add input validation schema
3. Implement business logic
4. Add error handling
5. Write unit tests
6. Update API documentation

## File Map
### New Files
- `src/routes/{name}.ts` - Route handler
- `src/validators/{name}.ts` - Validation schema
- `tests/routes/{name}.test.ts` - Unit tests

### Modified Files
- `src/routes/index.ts` - Register new route

## Acceptance Criteria
- [ ] Route responds with correct status codes
- [ ] Input validation rejects invalid data
- [ ] Authentication enforced if required
- [ ] Unit tests pass with >80% coverage
- [ ] API documentation updated
```

### Using Templates

Reference templates when creating tasks or projects. Claude will follow the template's workflow and ensure all acceptance criteria are met.

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
    └── prp-templates/
        └── api-endpoint.md      # API endpoint template
```
