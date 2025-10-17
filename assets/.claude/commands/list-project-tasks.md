# /list-project-tasks

List all tasks within a specific project, grouped by their current status.

## Usage
```
/list-project-tasks <project-name>
```

## Description
Displays all tasks that belong to a specific project, organized by their workflow status (planning, approved, in-progress, completed). This command helps you track progress on individual project tasks and see the overall task distribution for a project.

## Parameters
- `<project-name>`: The name of the project whose tasks you want to list (required)

## Examples
```bash
/list-project-tasks my-feature
/list-project-tasks user-authentication
```

## Output
```
# Task List for Project: my-feature
========================================

## planning (2 tasks)

  - implement-api-endpoint
    Created: 2024-01-15 10:30:00
    Template: api-endpoint
    
  - add-validation
    Created: 2024-01-15 11:00:00

## approved (1 tasks)

  - write-tests
    Created: 2024-01-14 15:00:00

## in-progress (1 tasks)

  - setup-database
    Created: 2024-01-13 09:00:00

## completed (3 tasks)

  - create-models
    Created: 2024-01-10 14:00:00
    Template: create-model

## Summary
Total tasks: 7
```

## Error Handling
- **AI playground not initialized**: Prompts to run `/init-playground` first
- **Project does not exist**: Shows error and suggests using `/list-projects` to see available projects
- **Missing project name**: Shows usage instructions

## Project Task Organization
Project tasks are stored in subdirectories within each project:
```
ai-playground/projects/[project-name]/tasks/
├── planning/      # Tasks being defined
├── approved/      # Tasks ready to implement
├── in-progress/   # Tasks currently being worked on
└── completed/     # Finished tasks
```

## Task Information Displayed
- Task name (derived from filename)
- Creation date
- PRP template used (if applicable)

## Related Commands
- `/list-projects` - List all projects
- `/create-project-task` - Create a new task within a project
- `/list-tasks` - List all global tasks (not project-specific)
- `/continue-project` - Resume work on a project and see its tasks