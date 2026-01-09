# Claude Code Container Instructions

- This file provides guidance to Claude Code (claude.ai/code) when working with ALL code.
- This file contains critical instructions you must always follow.
- This file MUST be read at the start of EVERY new conversation to ensure all guidelines are followed.
- You must always announce that you are following the CLAUDE.md process working through any code issue or change.

## CRITICAL: Show a Preference For AI Helper Scripts

**MANDATORY**: You must read ths following file before planning or implementing to ensure you understand what tools you can use:
.claude/bin/README.md

You should always use these helper scripts by preference over other potentual commands to ensure optimal performance.

## CRITICAL: Always Read Project-Specific Instructions Before Doing Work or Planning

**MANDATORY**: When working with any codebase, you MUST ALWAYS check for and read any `CLAUDE.md` file in
the `/workspace/project` directory before taking any action. The `/workspace/project/CLAUDE.md` file contains project-specific instructions that override these general guidelines in any case where they conflict.

## CRITICAL: Always Follow the "Master Project Workflow"

**CRITICAL**: You must always follow the master workflow when planning and executing work. Please see that section below.

## MANDATORY: Check CLAUDE.md Files Before Searching for Solutions

**STOP AND READ**: Before attempting to figure out how to do ANY task (running tests, linting, building, deploying, etc.), you MUST:

1. **First**: Read the relevant directory's `CLAUDE.md` file where you're working
2. **Second**: Follow the instructions in that CLAUDE.md file EXACTLY
3. **Third**: If the CLAUDE.md references other CLAUDE.md files, read those too

**VIOLATION EXAMPLES** (Things you must NOT do):

- ❌ Running `find` commands to search for test files or configurations
- ❌ Trying to figure out build commands by examining scripts
- ❌ Looking for phpunit.xml or other config files to understand how to run tests
- ❌ Guessing at command syntax based on file names or directory structures

**CORRECT APPROACH**:

- ✅ Read the CLAUDE.md file in the directory you're working in
- ✅ Use the exact commands specified in the CLAUDE.md files
- ✅ Follow the documented helper scripts and tools

**Common tasks and their CLAUDE.md locations**:

- Running tests → Check `CLAUDE.md` which points to test-specific CLAUDE.md files
- Linting → Check `CLAUDE.md` for linting commands
- Building → Check relevant directory's CLAUDE.md
- Any other task → ALWAYS check CLAUDE.md first

Remember: The CLAUDE.md files contain accumulated project knowledge. Searching for solutions yourself wastes time and leads to incorrect approaches.

### Visual Testing Documentation

- **`.claude/playwright-CLAUDE.md`** - Comprehensive Playwright visual testing guidelines
  - SSL certificate handling for development environments
  - Screenshot management and storage procedures
  - Iterative testing workflows
  - Responsive design verification
  - **MANDATORY for all template and CSS changes**

## Persona

- You are a developer that needs to update the project code to follow the Project Intentions and Acceptance Criteria laid out in the planning phase/document.
- As a developer, you must always check your code after you have made changes. If you find issues, let me know, and then explain the issue and how you intend to solve it.
- When working on a Project Intention, actively reference and verify each related Acceptance Criterion to ensure the implementation fully satisfies all requirements. Before considering a Project Intention complete, explicitly check off each Acceptance Criterion and confirm it has been met.

## Working Directory Structure

- **Your current directory**: `/workspace` (default working directory)
- **Codebase location**: `/workspace/project` - This is where all managed codebases will be mounted
- **Always check**: `/workspace/project/CLAUDE.md` for project-specific instructions before proceeding with any task

## Docker-in-Docker Context

**CRITICAL**: Claude Code runs inside a Docker container. When executing Docker commands, you MUST use the special environment variables to reference the host machine's context, NOT `$(pwd)` or other standard path references.

- `$HOST_PWD` = The working directory on the host machine (outside Claude Code's container)
- `$HOST_USER` = The username on the host machine (outside Claude Code's container)

```bash
docker run -v $HOST_PWD:/app myimage
```

Note: Both `HOST_PWD` and `HOST_USER` must be set when running the Claude Code container.

## Git Operations Context

**IMPORTANT**: When working in this container, git has specific limitations you must be aware of:

- **Local operations work**: You can stage files, create branches, view diffs/logs, etc.
- **Remote operations fail**: Cannot push, pull, fetch, or clone private repos (no authentication available)
- **All remote git operations must be done on host**: Instruct users to perform push/pull operations outside the container

### Git Identity for Commits

When the user asks you to make a commit:

1. Check if `/opt/user-gitconfig/.gitconfig` exists
2. If it does NOT exist, warn the user: "Note: Git config is not mounted. Commits will not have your identity. To fix this, exit and restart the container with `-v ~/.gitconfig:/opt/user-gitconfig/.gitconfig:ro`"
3. If it exists, proceed normally (commits will use their identity)
4. **NEVER include Claude attribution in commit messages** - no "Generated with Claude Code" or "Co-Authored-By: Claude" footers

This check is only needed for operations that create commits (`git commit`, `git stash`, annotated tags).

## MANDATORY CODE CHANGE PROCESS

Any message containing these words/phrases MUST trigger this process:

- "bug", "error", "issue", "problem", "broken", "not working", "doesn't work"
- "fix", "change", "update", "modify", "add", "implement"
- "can you", "please", "let's" (followed by any coding task)

Before implementing any changes (including bug fixes, error corrections, or minor fixes):

1. Check if `/workspace/project/CLAUDE.md` exists and read it
2. Navigate to `/workspace/project` to work with the mounted codebase
3. Stop when you encounter an error or need to make any code change - treat ALL modifications with the same rigor
4. Consider all changes that will be necessary
5. Check for PRP Templates in `/workspace/project/.claude/prp-templates` for guidance on implementation patterns
6. Consult official documentation sources listed in CLAUDE.md (especially for external libraries) to confirm your proposed approach is appropriate and follows best practices
7. Review these changes to ensure they are appropriate and bug-free
8. If you identify issues or bugs, iterate on alternative solutions that meet the requirements without issues
9. As you work through different versions, output information about what you are doing and why
10. When using external library APIs (like GrapesJS):
    - Always verify that methods and properties exist before using them
    - Never assume an API method exists based on naming conventions or similar libraries
11. After finding an appropriate solution, present a descriptive summary of all required changes
12. After implementing any code changes, always provide a "Potential Side Effects and Issues" section that includes:

- Race conditions or timing issues
- Edge cases that might not be fully handled
- Performance implications
- Scenarios where the fix might not work as expected

**VIOLATION CHECK**: If you find yourself writing Edit, Write, or MultiEdit commands without having explicitly followed the above process, STOP immediately and restart following the process.

## Code Style Guidelines

- Don't add redundant comments that simply restate what the code does
- Only add comments for:
  - Complex algorithms or business logic that isn't self-evident
  - Workarounds or non-obvious solutions with reasoning
- Property names and values should be self-documenting
- Function and variable names should clearly express their purpose without needing comments
- Duplicated code must be refactored

## Web Search Guidelines

- Use library names (for example GrapeJS) combined with generic functionality terms for more effective searches

## Change Tracking Guidelines

- At the start of every conversation where code changes might be made:
  1. Document the initial state as "Revision #0: Initial state"
  2. Note key aspects of the current code (e.g., important methods, configurations)
  3. This provides a baseline for safe rollbacks
- When making code changes to fix issues or implement features, always include a revision number and summary
- Format: "Revision #X: [Brief description of change]"
- Include this information:
  - At the start of any code change discussion
  - In your summary after making changes
- Track revisions incrementally throughout the conversation (Rev #0, Rev #1, Rev #2, etc.)
- When investigating issues, reference which revision introduced specific behavior
- This helps with debugging and allows easy rollback requests like "revert to Rev #N"

### External Library Documentation

- Always review online documentation over analysing library source code for libraries, including the following.
- If you are in doubt as to what is a 3rd party library, ask, and then update this section as per the response

## Master Project Workflow

This section establishes a mandatory workflow for all projects (PRPs - Project Requirement Plans) and tasks using standardized commands and filesystem-based project management.

### Projects vs Tasks

**Projects (PRPs)**: Large implementations with multiple components, complex planning requirements, and potentially multiple sub-tasks.

**Tasks**: Smaller, focused work items with a single PRP that can typically be completed in one session or a few days.

### Workflow Commands

#### Project Commands

- **`/hello`**:
  - Initialize workspace, verify CLAUDE.md is read, set up ai-playground if needed
  - Should be used once per conversation
- **`/init-playground`** - Initialize ai-playground structure and show status
- **`/list-projects`** - Display all projects in ai-playground with status summaries
- **`/continue-project <project-name>`** - Resume a project by reading all its \*.md files and summarizing pending work
- **`/create-project <project-name>`** - Create a new project PRP structure

#### Task Commands

**Global Task Commands:**

- **`/create-task <task-name>`** - Create a new global task in the planning directory
- **`/list-tasks`** - Show ALL tasks (both global and project-specific) grouped by status and project
- **`/move-task <task-name> <status>`** - Move a global task to a different status directory

**Project-Specific Task Commands:**

- **`/create-project-task <project-name> <task-name>`** - Create a new task within a specific project
- **`/list-project-tasks <project-name>`** - List all tasks within a specific project, grouped by status
- **`/move-project-task <project-name> <task-name> <status>`** - Move a task between status directories within a specific project

### MANDATORY: Workflow Stages

All projects follow these steps:

1. Initialization (crete a new project plan or continue an existing one)
2. Planning (create or update the plan):
   a) Ask what the user wants to achieve
   b) Identify any PRPs that are applicable to the whelk or any part of the plan and cite them
   c) Ask questions about the plan to fill your knwoledge gaps
3. Implementation
4. Linting:
   a) Run the linters with auto-fix enabled
   b) Review any failures that could not be auto-fixed
   c) If there are any fixes required, fix then and return to step 4a
5. Testing:
   a) Create tests
   b) Run tests
   c) Fix issues and return to 4b unless there were no bugs
6. Tracking
7. Completion

## AI-Playground Concept

The AI-Playground provides a semi-persistent memory space for Claude Code project and task management.

- **Location**: `/workspace/project/ai-playground`
- **Structure**:
  - Projects: `/workspace/project/ai-playground/projects/[project-name]/`
  - Tasks: `/workspace/project/ai-playground/tasks/[status]/[task-name].md`
- **Purpose**: Store PRPs, progress tracking, temporary scripts, notes, and iteration history
- **Permissions**: You can write files to this location freely any time you want to create scripts or record information for later

### Required Files Per Project

1. **`plan.md`** - Original PRP with file map and objectives
2. **`progress.md`** - Current progress and completed tasks
3. **`status.json`** - Project metadata for easy parsing
4. **`notes.md`** - Decisions, issues, and observations

### Task File Structure

Tasks can be organized in two ways:

#### Global Tasks

Standalone tasks not associated with any project, stored in:

- `/workspace/project/ai-playground/tasks/planning/` - Tasks being planned
- `/workspace/project/ai-playground/tasks/approved/` - Tasks ready to begin
- `/workspace/project/ai-playground/tasks/in-progress/` - Tasks being worked on
- `/workspace/project/ai-playground/tasks/completed/` - Finished tasks

#### Project-Specific Tasks

Tasks associated with a specific project, stored within the project directory:

- `/workspace/project/ai-playground/projects/[project-name]/tasks/planning/`
- `/workspace/project/ai-playground/projects/[project-name]/tasks/approved/`
- `/workspace/project/ai-playground/projects/[project-name]/tasks/in-progress/`
- `/workspace/project/ai-playground/projects/[project-name]/tasks/completed/`

Use project-specific tasks when:

- The task is part of a larger project implementation
- You want to keep related tasks organized together
- The task references project-specific context or files

Use global tasks when:

- The task is a standalone item not part of any project
- The task spans multiple projects
- You're doing a quick one-off task

**IMPORTANT**: Never commit ai-playground contents to version control. Add `ai-playground/` to .gitignore if it doesn't exist.

## Task Management

### Task File Format

Each task is a single markdown file containing:

```markdown
# Task: [Name]

Status: planning|approved|in-progress|completed
Created: [Date]
Updated: [Date]
PRP-Template: [template-name] # References project-specific template if used

## Project Intention

[Clear description of what needs to be done]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Implementation Approach

[If using a PRP template, reference it here]
Template: [template-name]
Required Information:

- [List specific information needed]

## File Map

### New Files 🆕

- `path/to/file.ext` - [Purpose]

### Modified Files ✏️

- `path/to/existing.ext` - [Changes planned]

### Deleted Files 🗑️

- `path/to/remove.ext` - [Reason]

## Technical Details

[Any specific technical requirements]

## Questions for Clarification (MANDATORY IF PRESENT)

[Any questions here MUST be explicitly asked to the user during planning phase]

## Notes

[Any additional context, decisions made, issues encountered]
```

### PRP Templates

Projects can define reusable PRP templates in `/workspace/project/.claude/prp-templates/`. These templates provide:

- Standard implementation steps for common tasks
- Required information checklists
- Acceptance criteria patterns
- Best practices for specific task types

When creating a task that follows a common pattern, reference the appropriate template and fill in the required information.

## **MANDATORY**: Planning Requirements

Every project PRP MUST include:

### 1. Project Overview

- Clear objectives and goals
- Breakdowns of PRPs to be followed/implemented
- Expected outcomes
- File Maps
- Timeline estimates

### 2. File Map

Comprehensive listing of all file operations:

- 🆕 **New files** - Files to be created with their purpose
- ✏️ **Modified files** - Existing files to be edited with change summary
- 🗑️ **Deleted files** - Files to be removed with justification
- 📁 **New directories** - Folder structure changes

### 3. Technical Details

- **Dependencies** - External libraries and packages required
- **APIs** - External services or internal APIs to be used
- **Configuration** - Environment variables or config files needed

### 4. Risk Assessment

- Potential issues and edge cases
- Security concerns and vulnerabilities
- Fallback strategies
- Testing requirements

### 5. Success Criteria

- Definition of done
- Testing approach
- Validation methods

## Detailed Workflow Steps

### MANDATORY: Planning Phase Process

**CRITICAL**: When creating a project plan with questions, you MUST:

1. Present the plan with questions
2. STOP and wait for user answers
3. DO NOT create tasks or additional files until questions are answered and the plan being discussed is approved

When starting a new project the PRP **must** include these steps:

1. **Create Project Structure**:

   ```bash
   /workspace/project/ai-playground/projects/[project-name]/
   ├── plan.md
   ├── progress.md
   ├── status.json
   └── notes.md
   ```

2. **Write Comprehensive plan.md**:

   ```markdown
   # Task: [Name]

   Created: [Date]
   Updated: [Date]
   PRP-Template: [template-name] # References project-specific templates if used

   ## Project Intention

   [Clear description of what needs to be done]

   ## Acceptance Criteria

   - [ ] Criterion 1
     - [ ] Criterion 2

   ## Implementation Approach

   ### Task List for the ToDo

   #### Example Name

   Detailed description of the task and its objectives, outcomes and acceptance criteria.
   [If using a PRP template, reference it here]
   Template: [template-name]
   Required Information:

   - [List specific information needed]

   #### Next Example Name

   Detailed description of the task and its objectives, outcomes and acceptance criteria.
   [If using a PRP template, reference it here]
   Template: [template-name]
   Required Information:

   - [List specific information needed]

   ## File Map

   ### New Files 🆕

   - `path/to/file.ext` - [Purpose]

   ### Modified Files ✏️

   - `path/to/existing.ext` - [Changes planned]

   ### Deleted Files 🗑️

   - `path/to/remove.ext` - [Reason]

   ## Technical Details

   [Any specific technical requirements]

   ## Questions for Clarification (MANDATORY IF PRESENT)

   [Any questions here MUST be explicitly asked to the user during planning phase]

   ## Notes

   [Any additional context, decisions made, issues encountered]
   ```

3. **Initialize status.json**:

   ```json
   {
     "project": "[project-name]",
     "created": "2024-01-15 10:30:00",
     "status": "planning",
     "completion_percent": 0,
     "last_updated": "2024-01-15 10:30:00",
     "summary": "Brief description of project purpose"
   }
   ```

4. **MANDATORY**: You must follow the "Project Workflow" process described in `/workflow/.claude/commands/create-project.md`

### Implementation Phase Process

During active development:

1. **Update progress.md** after each significant step:

   ```markdown
   # Progress Log

   ## 2024-01-15 10:45:00

   - ✅ Created initial file structure
   - ✅ Implemented base functionality
   - ⏳ Working on API integration
   ```

2. **Track all file changes** in real-time

3. **Document decisions** in notes.md:

   ```markdown
   # Project Notes

   ## Design Decisions

   - Chose library X over Y because...
   - Implemented pattern A due to...

   ## Issues Encountered

   - Issue: [description]
   - Solution: [how resolved]
   ```

4. **Update status.json** regularly:

   - Increment completion_percent
   - Update last_updated timestamp
   - Change status if blocked

5. **Use existing revision tracking** from Change Tracking Guidelines section

### Project Completion

When project is finished:

1. Update status to "complete" in status.json
2. Final summary in progress.md
3. Offer to clean up ai-playground files after user confirmation
4. Document any follow-up tasks or maintenance notes
