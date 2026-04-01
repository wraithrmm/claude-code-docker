---
name: count-projects
description: Return the number of projects currently in the ai-playground. Utility command used internally by other skills.
disable-model-invocation: true
---

# Count the number of projects in the ai-playground

## Usage
```
/count-projects
```

## Description
Returns a single number representing the count of project directories in `/workspace/project/ai-playground/projects/`. Primarily used internally by other scripts but useful for quick checks.

## Output
```bash
$ /count-projects
3
```

If no projects exist:
```bash
$ /count-projects
0
```

## Technical Details
- Counts only directories directly under `/workspace/project/ai-playground/projects/`
- Does not count files or nested directories
- Returns 0 if the projects directory doesn't exist

## Related Skills
- `/list-projects` - Show detailed information about all projects
- `/init-playground` - Initialize the ai-playground structure
