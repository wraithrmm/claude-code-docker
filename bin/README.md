# Claude Code Launcher

A wrapper script to run Claude Code in Docker with automatic dependency management.

## Quick Start

```bash
# From the repository root
./bin/run-claude-code
```

That's it! The script will:
1. Check if Docker is installed (with installation tips if not)
2. Create any missing dependencies automatically
3. Launch the Claude Code container

## Options

| Flag | Description |
|------|-------------|
| `--host-network` | Use host networking instead of bridge (default) |
| `--no-docker-sock` | Don't mount Docker socket into container |
| `--dry-run` | Print the docker command without executing |
| `--help` | Show help message |

## Examples

```bash
# Default (bridge networking)
./bin/run-claude-code

# With host networking (needed for some local services)
./bin/run-claude-code --host-network

# See what command would run without executing
./bin/run-claude-code --dry-run

# Without Docker-in-Docker capability
./bin/run-claude-code --no-docker-sock
```

## Dependencies

The script automatically creates these if they don't exist:

| Path | Purpose |
|------|---------|
| `~/.claude.json` | Claude authentication/configuration |
| `~/.claude/` | Claude persistent state |
| `/Users/claude-code/` (macOS) | Shared workspace directory |
| `/home/claude-code/` (Linux) | Shared workspace directory |

## What Gets Mounted

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| Current directory | `/workspace/project` | Your codebase |
| `~/.claude.json` | `/root/.claude.json` | Auth config |
| `~/.claude/` | `/root/.claude/` | Persistent state |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker-in-Docker |
| `/Users/claude-code/` or `/home/claude-code/` | Same path | Shared files |

## Environment Variables

The container receives these environment variables:

| Variable | Value |
|----------|-------|
| `HOST_PWD` | Current working directory on host |
| `HOST_USER` | Username on host machine |
| `RUN_AS_ROOT` | `true` |

## Troubleshooting

### Docker not found
The script will show platform-specific installation instructions.

### Permission denied creating workspace directory
On macOS/Linux, the workspace directory (`/Users/claude-code/` or `/home/claude-code/`) may need sudo:
```bash
sudo mkdir -p /Users/claude-code  # macOS
sudo chown $(whoami) /Users/claude-code

# or on Linux
sudo mkdir -p /home/claude-code
sudo chown $(whoami) /home/claude-code
```

### Docker daemon not running
- **macOS**: Start Docker Desktop
- **Linux**: `sudo systemctl start docker`
