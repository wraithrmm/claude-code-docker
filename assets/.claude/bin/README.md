# AI Helper Scripts

This directory (`/workspace/.claude/bin/` in the container) is for helper scripts you want available in every session. The image ships only this README here.

## Workflow Scripts Have Moved

The project and task management scripts (`init-playground`, `create-project`, `create-task`, `list-tasks`, `move-task` and the rest) are no longer here. They are part of the `workflow` Claude Code plugin from the `wraithrmm/claude-workflow` repository and live inside the container at:

```text
/opt/claude-plugins/current/plugins/workflow/scripts/
```

Run them through their skills (`/init-playground`, `/create-project`, `/create-task`, ...) rather than calling the scripts directly. Skills reference them as `${CLAUDE_PLUGIN_ROOT}/scripts/<name>`.

## Project Scripts

Projects can still provide their own helper scripts in `/workspace/project/.claude/bin/`. Document them in the project's `CLAUDE.md` so Claude knows to prefer them.
