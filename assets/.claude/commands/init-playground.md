# Initialize the ai-playground directory structure and show current status

## Usage
```
/init-playground
```

## Description
This command sets up the ai-playground directory structure if it doesn't exist and displays the current status of projects and tasks. It should typically be run at the start of a conversation via the `/hello` command.

## What it does
1. Creates the ai-playground directory structure:
   ```
   /workspace/project/ai-playground/
   ├── projects/        # For large PRPs
   └── tasks/          # For smaller tasks
       ├── planning/
       ├── approved/
       ├── in-progress/
       └── completed/
   ```

2. Lists existing projects with numbers
3. Counts total tasks across all statuses
4. Provides guidance on next steps

## Output Example
```
Following CLAUDE.md process
✅ ai-playground directory exists

Existing projects:
1. 📁 ecommerce-redesign
2. 📁 api-migration

Ready for new work:
- Found 2 project(s)
- Found 5 task(s)

Use /list-projects to see projects or /list-tasks to see tasks
```

## Related Commands
- `/list-projects` - Show detailed project information
- `/list-tasks` - Show tasks by status
- `/create-project` - Create a new project
- `/create-task` - Create a new task