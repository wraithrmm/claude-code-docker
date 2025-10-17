# /move-project-task

Move a task between status directories within a specific project

## Usage
```
/move-project-task <project-name> <task-name> <status>
```

## Description
Moves a task from its current status to a new status within a specific project's task management structure. This command updates the task's status field and timestamp while preserving all other content.

The command searches for the task across all status directories within the specified project and moves it to the target status directory.

## Parameters
- `<project-name>`: The name of the project containing the task (required)
- `<task-name>`: The name of the task to move (without .md extension) (required)
- `<status>`: The target status (required). Valid values:
  - `planning` - Task is being planned
  - `approved` - Task is approved and ready to work on
  - `in-progress` - Task is currently being worked on
  - `completed` - Task has been completed

## Examples
```bash
# Move a task from planning to approved
/move-project-task my-project implement-feature approved

# Start working on an approved task
/move-project-task my-project implement-feature in-progress

# Mark a task as completed
/move-project-task my-project implement-feature completed

# Move a completed task back to planning for revision
/move-project-task my-project implement-feature planning
```

## Output
The command provides:
- Confirmation of the move with source and destination status
- Context-appropriate next steps based on the target status
- Error messages if the project/task is not found or status is invalid

## Error Handling
- **Missing arguments**: Shows usage instructions
- **Invalid status**: Lists valid status options
- **Project not found**: Suggests using `/list-projects` to see available projects
- **Task not found**: Suggests using `/list-project-tasks <project-name>` to see available tasks
- **Task already in target status**: Confirms current status without error
- **AI playground not initialized**: Prompts to run `/init-playground` first

## Related Commands
- `/create-project-task` - Create a new task within a project
- `/list-project-tasks` - List all tasks within a specific project
- `/move-task` - Move tasks in the global task directory (not project-specific)
- `/list-projects` - Show all available projects