---
name: create-task
description: Create a new standalone task with PRP template in the global planning directory.
disable-model-invocation: true
argument-hint: <task-name>
---

# Create a new task in the planning directory

## Usage
```
/create-task <task-name>
```

## Description
Creates a new task file in the `/workspace/project/ai-playground/tasks/planning/` directory with a standard PRP template. The task starts in the "planning" status and can be moved through the workflow using the `/move-task` command.

### **MANDATORY**: Goals

Your goal is to generate a new PRP for a specific task and create a document (using one of the PRP templates if an appropriate one exists) that can be used as a task to be completed.

1. Get the task name if not already provided (**MANDATORY**: You may not proceed without a task name).
2. Create the task with this command:
   ```bash
   /workspace/.claude/bin/create-task $ARGUMENTS
   ```
3. You must read the files in this directory before beginning to plan: `/workspace/project/.claude/prp-templates`
4. Suggest a PRP template that seems to reprosent the requested task's implementation requirements. 
5. Complete the planning phase and populate the task PRP document.

**IMPORTANT:** You are not implementing. Your success criteria is that you have created a task with a plan in it that the user has approved.

## Parameters
- `$ARGUMENTS`: The name of the task (will be used as the filename without .md extension)

## Task Workflow
1. **planning** - Task is being defined
2. **approved** - Task is ready to begin
3. **in-progress** - Task is being worked on
4. **completed** - Task is finished

## Next Steps
After creating a task:
1. Edit the task file to add specific requirements
2. Reference a PRP template if applicable
3. Always identify and seperate Infrastructure vs Application-Level concerns
4. Use `/move-task <task-name> approved` when ready to begin

## Related Skills
- `/list-tasks` - View all tasks by status
- `/move-task` - Move a task to a different status
- `/create-project` - Create a larger project PRP
