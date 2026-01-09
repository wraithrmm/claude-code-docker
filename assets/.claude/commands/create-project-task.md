# /create-project-task

Create a new task within a specific project directory

## Usage
```
/create-project-task <project-name> <task-name>
```

## Description
Creates a new task file within an existing project's task directory structure. This command is used when you want to add a new task to a specific project, maintaining the task within the project's own directory hierarchy rather than the global task directory.

The task is created in the project's `planning` directory and follows the standard task file format with sections for Project Intention, Acceptance Criteria, Implementation Approach, Technical Details, and Notes.

## Parameters
- `<project-name>`: The name of the existing project where the task should be created (required)
- `<task-name>`: The name of the new task to create (required)

## Examples
```bash
/create-project-task e-commerce-site user-authentication
/create-project-task api-migration add-rate-limiting
/create-project-task frontend-refactor implement-dark-mode
```

## Output
When successful:
- Creates task file at: `/workspace/project/ai-playground/projects/<project-name>/tasks/planning/<task-name>.md`
- Displays success message with task location
- Provides next steps for editing and approving the task

## Error Handling
- **Missing arguments**: Shows usage and exits with code 1
- **Project not found**: Suggests using `/create-project` first and exits with code 1
- **Task already exists**: Prevents duplicate creation and exits with code 1

## Related Commands
- `/create-project` - Create a new project before adding tasks
- `/move-project-task` - Move task between workflow states (planning → approved → in-progress → completed)
- `/list-projects` - View all projects and their status
- `/create-task` - Create a task in the global tasks directory (not project-specific)

## Notes
- Tasks created with this command are specific to a project and stored within the project's directory
- The task starts in `planning` status and must be approved before implementation
- Task names should be descriptive and use hyphens for spaces (e.g., `implement-feature` not `implement feature`)
- Consider referencing PRP templates from `/workspace/project/.claude/prp-templates/` when filling out the task details