# Create a new project with a full PRP structure

## Usage
```
/create-project <project-name>
```

## Description
Creates a new project directory in `/workspace/project/ai-playground/projects/` with all required PRP files. Projects are for larger implementations that may contain multiple tasks or complex planning requirements.

### **MANDATORY**: Goals

Your goal is to generate a new PRP (or collection thereof) for a specific project.

Always identify and seperate Infrastructure vs Application-Level concerns so that tasks can be assigned to DevOps and Dev respectively.

#### Project Workflow

1. Get the project name if not already provided (**MANDATORY**: You may not proceed without a project name).
2. Create the project with this command:
   ```bash
   /workspace/.claude/bin/create-project <project-name>
   ```
3. You must read the files in this directory before beginning to plan: `/workspace/project/.claude/prp-templates`
4. Start planning with the user:
   a. Present the plan to the user.
   b. **MANDATORY**: If the plan contains a "Questions for Clarification" section or any unresolved questions, you MUST explicitly ask these questions to the user NOW before proceeding.
   c. Ask them for feedback or approval.
5. **CRITICAL STOP POINT**: Do NOT proceed to create any tasks, supporting files, or additional documentation until:
  - The user has answered all questions
  - The plan has been explicitly approved
  - You have updated the plan with any clarifications
6. If the user approved the plan, stop planning and skip to step 7, otherwise return to step 4
7. Verify! Once you have the plan laid out, and every time you change it, you must return to step 4 to get user approval
8. Scan the plan and identify tasks within it that can be satisfied by a PRP template in the `/workspace/project/.claude/prp-templates` directory, e.g. if the task involved creating a database field, then use the migration template for that task in the project. 
9. Edit plan.md to define requirements using the established PRP format within this codebase 
10. Update the status to "approved" when approved for implementation

**IMPORTANT:** You are not implementing. Your success criteria is that you have created a project PRP with all supporting tasks with a master plan in it that the user has approved.

## Parameters
- `<project-name>`: The name of the project (used as directory name)

## Example
```
/create-project ecommerce-checkout-redesign
```

This creates:
```
/workspace/project/ai-playground/projects/ecommerce-checkout-redesign/
├── plan.md         # Project PRP with file map and objectives
├── progress.md     # Progress tracking log
├── status.json     # Project metadata
└── notes.md        # Design decisions and issues
```

## Files Created

### plan.md
The main PRP document containing:
- Project overview and goals
- Lists of supporting PRP files
- File map (new, modified, deleted files)
- Implementation steps
- Success criteria
- Risk assessment
- Dependencies

### progress.md
A chronological log of progress with:
- Timestamped entries
- Completed items (✅)
- In-progress items (⏳)
- Blockers or issues

### status.json
Machine-readable project metadata:
```json
{
    "project": "project-name",
    "created": "timestamp",
    "status": "planning|active|blocked|complete",
    "completion_percent": 0-100,
    "last_updated": "timestamp",
    "summary": "brief description"
}
```

### notes.md
Additional documentation for:
- Design decisions and rationale
- Issues encountered and solutions
- References to tickets, docs, etc.

## Related Commands
- `/list-projects` - View all projects and statuses
- `/continue <project-name|number>` - Resume work on a project by name of number (from the /list-project command)
- `/create-task` - Create a smaller, focused task