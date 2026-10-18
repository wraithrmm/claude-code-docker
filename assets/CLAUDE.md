# Claude Code Container Instructions

- This file provides guidance to Claude Code (claude.ai/code) when working with ALL code.
- This file contains critical instructions you must always follow.
- You must always announce that you are following the CLAUDE.md process working through any code issue or change.

## CRITICAL: Show a Preference For AI Helper Scripts

**MANDATORY**: Before planning or implementing, check for helper scripts the project provides (for example `/workspace/project/.claude/bin/` and any README there, or scripts named in the project's `CLAUDE.md`). Always use these helper scripts by preference over other potential commands to ensure optimal performance.

The workflow scripts (projects, tasks, ai-playground) are run through the `workflow` plugin's skills; invoke the skill rather than calling the script directly.

## CRITICAL: Project-Specific Instructions Override These

The mounted project's `CLAUDE.md`, `.claude/rules/`, agents, skills and commands are loaded into the session automatically, and a nested `CLAUDE.md` loads when you work on files in its directory. Do not re-read them with the Read tool; they are already in context. Where project instructions conflict with these general guidelines, the project instructions win.

## CRITICAL: Always Follow the "Master Project Workflow"

**CRITICAL**: You must always follow the master workflow when planning and executing work. See the "Master Project Workflow" section below.

## MANDATORY: Use the Documented Commands Before Searching for Solutions

**STOP**: Before attempting to figure out how to do ANY task (running tests, linting, building, deploying, etc.), you MUST:

1. **First**: Look for the command in the CLAUDE.md instructions already loaded for the project and the directory you're working in
2. **Second**: Follow those instructions EXACTLY
3. **Third**: If a CLAUDE.md points to another document that is not already loaded (for example a test-specific guide), read that document

**VIOLATION EXAMPLES** (Things you must NOT do):

- ❌ Running `find` commands to search for test files or configurations
- ❌ Trying to figure out build commands by examining scripts
- ❌ Looking for test runner config files to understand how to run tests
- ❌ Guessing at command syntax based on file names or directory structures

**CORRECT APPROACH**:

- ✅ Use the exact commands specified in the CLAUDE.md files
- ✅ Follow the documented helper scripts and tools

Running tests, linting, building or any other task: the CLAUDE.md instructions come first.

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
- **The container has no git credentials of its own**: plain `git push`, `pull`, `fetch` and cloning private repos fail
- **Use the project's remote helper when it has one**: if the project documents an authenticated helper for pushing, fetching or opening pull requests, use it for remote operations
- **Otherwise remote operations are done on the host**: instruct users to perform push/pull operations outside the container

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

1. Navigate to `/workspace/project` to work with the mounted codebase
2. Stop when you encounter an error or need to make any code change - treat ALL modifications with the same rigor
3. Consider all changes that will be necessary, and check whether an available skill covers the implementation pattern
4. Consult official documentation sources listed in CLAUDE.md (especially for external libraries) to confirm your proposed approach is appropriate and follows best practices
5. Review these changes to ensure they are appropriate and bug-free
6. If you identify issues or bugs, iterate on alternative solutions that meet the requirements without issues
7. As you work through different versions, output information about what you are doing and why
8. When using external library APIs:
   - Always verify that methods and properties exist before using them
   - Never assume an API method exists based on naming conventions or similar libraries
9. After finding an appropriate solution, present a descriptive summary of all required changes
10. After implementing any code changes, always provide a "Potential Side Effects and Issues" section that includes:

- Race conditions or timing issues
- Edge cases that might not be fully handled
- Performance implications
- Scenarios where the fix might not work as expected

**VIOLATION CHECK**: If you find yourself writing Edit or Write commands without having explicitly followed the above process, STOP immediately and restart following the process.

## Code Style Guidelines

- Don't add redundant comments that simply restate what the code does
- Only add comments for:
  - Complex algorithms or business logic that isn't self-evident
  - Workarounds or non-obvious solutions with reasoning
- Property names and values should be self-documenting
- Function and variable names should clearly express their purpose without needing comments
- Duplicated code must be refactored

## Web Search Guidelines

- Use library names combined with generic functionality terms for more effective searches

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

- Always review online documentation over analysing library source code for libraries.
- If you are in doubt as to what is a 3rd party library, ask.

## Master Project Workflow

The project and task workflow (PRPs - Project Requirement Plans, tracked in the ai-playground) is provided by the `workflow` Claude Code plugin. **Load the `workflow-guide` skill for the full process**: projects vs tasks, PRP and task file formats, required project files, planning requirements, implementation tracking and completion.

### Commands

Skills are invoked by bare name (`/hello`) unless a local skill with the same name exists, in which case use `/workflow:<name>`. Agents always need the prefix.

| Command / Agent | Purpose |
| --- | --- |
| `/hello` | Initialize the workspace and ai-playground; use once per conversation |
| `/init-playground`, `/list-projects`, `/count-projects` | Set up and inspect the ai-playground |
| `/create-project <name>`, `/continue-project <name>`, `/verify-project <name>` | Create, resume or check a project PRP |
| `/create-task <name>`, `/list-tasks`, `/move-task <name> <status>` | Global tasks |
| `/create-project-task <project> <task>`, `/list-project-tasks <project>`, `/move-project-task <project> <task> <status>` | Project-specific tasks |
| `/add-acceptance-criteria <feature> <use-case>` | Add acceptance criteria to a feature, implement and test |
| `workflow:lint-runner` agent | Run linters with auto-fix and report |
| `workflow:unit-test-runner` agent | Run unit tests and report |
| `workflow:playwright-visual-tester` agent | Browser verification and screenshots |

### MANDATORY Rules

- **Always follow the workflow stages**: Initialization, Planning, Implementation, Linting (run linters with auto-fix, fix what remains, repeat), Testing (create tests, run them, fix and re-run until clean), Tracking, Completion. Linting and testing are never skipped.
- **Planning**: when presenting a plan with questions, STOP and wait for the user's answers. Do not create tasks or further files until the questions are answered and the plan is approved.
- **AI-Playground** lives at `/workspace/project/ai-playground` (projects in `projects/[project-name]/`, tasks in `tasks/[status]/`). You may write there freely.
- **Never commit ai-playground contents** to version control. Add `ai-playground/` to `.gitignore` if it is missing.
