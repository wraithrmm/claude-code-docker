# Move a task to a different status in the workflow

## Usage
```
/move-task <task-name> <status>
```

## Description
Moves a task file between status directories, updating its status and timestamp. This command manages the task workflow progression.

## Parameters
- `<task-name>`: The name of the task to move
- `<status>`: The target status (planning, approved, in-progress, completed)

## Valid Status Values
- `planning` - Task is being defined
- `approved` - Task is ready to begin
- `in-progress` - Task is being worked on
- `completed` - Task is finished

## Examples
```bash
# Approve a task for implementation
/move-task implement-user-auth approved

# Start working on a task
/move-task implement-user-auth in-progress

# Mark a task as completed
/move-task implement-user-auth completed

# Move a task back to planning for revision
/move-task implement-user-auth planning
```

## What Happens
When you move a task:
1. The task file is moved to the new status directory
2. The Status field is updated in the file
3. The Updated timestamp is refreshed
4. The original file is removed from the old location

## Workflow Best Practices
1. **planning → approved**: Task requirements are clear and complete
2. **approved → in-progress**: You're starting work on the task
3. **in-progress → completed**: All acceptance criteria are met
4. Tasks can move backwards if revision is needed

## File Changes
The command updates these fields in the task file:
```markdown
Status: [new-status]
Updated: [current-timestamp]
```

## Error Handling
- Task must exist in one of the status directories
- Target status must be valid
- If task is already in target status, no action is taken

## Related Commands
- `/create-task` - Create a new task
- `/list-tasks` - View all tasks by status
- `/create-project` - Create a larger project PRP