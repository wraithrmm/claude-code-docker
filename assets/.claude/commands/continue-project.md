# Continue an existing project you have underway

1. **Run the continue project script with project name:**
   ```bash
   /workspace/.claude/bin/continue-project <project-name|number>
   ```

2. **After script runs, read the project files:**
   ```
   Read("/workspace/project/ai-playground/projects/<project-name>/plan.md")
   Read("/workspace/project/ai-playground/projects/<project-name>/progress.md")
   Read("/workspace/project/ai-playground/projects/<project-name>/status.json")
   Read("/workspace/project/ai-playground/projects/<project-name>/notes.md")
   ```

3. **Generate comprehensive summary:**
   - Extract objectives from plan.md
   - List completed tasks from progress.md (lines with ✅)
   - List pending tasks from progress.md (lines with ⏳)
   - Identify blockers from notes.md or status
   - Format output as:
     ```
     📋 Resuming Project: [name]
     
     Original Objectives:
     - [objective 1]
     - [objective 2]
     
     Completed Tasks: ✅
     - [completed task 1]
     - [completed task 2]
     
     Pending Tasks: ⏳
     - [pending task 1]
     - [pending task 2]
     
     Current Blockers: 🚧
     - [blocker if any]
     
     Next Steps:
     1. [specific next action]
     2. [following action]
     ```

4. **Update TodoWrite tool:**
   - Parse pending tasks from progress.md
   - Create todo items for each pending task
   - Use TodoWrite tool to populate the todo list
   - Review the Todo list and ask the user questions about anything you are uncertain about

5. **Update project files as you work:**
   - Use Edit/Write tools to update progress.md with completed tasks
   - Update status.json with new completion percentage and timestamp
   - Add any important decisions or issues to notes.md (imagine at any point you might get shut down and so need to pick up where you left off)