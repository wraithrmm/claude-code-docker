# Display all tasks grouped by their current status

## Usage
```
/list-tasks
```

## Description
Lists all tasks in the AI playground, organized by their workflow status (planning, approved, in-progress, completed). Shows task counts and basic metadata for each task.

## Output Format
```
# Task List
============

## planning (2 tasks)

  - implement-user-auth
    Created: 2024-01-15 10:30:00
    Template: implement-api-endpoint
    
  - refactor-product-queries
    Created: 2024-01-15 11:00:00

## approved (1 tasks)

  - add-caching-layer
    Created: 2024-01-14 15:00:00
    Template: add-caching

## in-progress (1 tasks)

  - fix-validation-bug
    Created: 2024-01-13 09:00:00

## completed (3 tasks)

  - create-user-migration
    Created: 2024-01-10 14:00:00
    Template: create-migration

## Summary
Total tasks: 7
```

## Task Information Displayed
- Task name (filename without .md)
- Creation date
- PRP template used (if any)

## Task Status Meanings
- **planning**: Task is being defined, requirements gathering
- **approved**: Task is ready to begin implementation
- **in-progress**: Task is currently being worked on
- **completed**: Task has been finished

## Usage Tips
1. Use this command to get an overview of all tasks
2. Tasks should move through statuses sequentially
3. Only one task should typically be in-progress at a time
4. Completed tasks can be archived or deleted periodically

## Related Commands
- `/create-task` - Create a new task
- `/move-task` - Change a task's status
- `/create-project` - Create a larger project PRP