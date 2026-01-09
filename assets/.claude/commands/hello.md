# Begin Claude Code conversation workflows (always run this)

1. **Verify CLAUDE.md is loaded:**
   - Check if the file content is in current context
   - If not present, use: `Read(/workspace/CLAUDE.md)`
   - Also load project-specific instructions: @/workspace/project/.claude/CLAUDE.md

2. **Run initialization script:**

   ```bash
   /workspace/.claude/bin/init-playground
   ```

Once you have done this, you should ask the user what they want to work on.
