# Count the number of projects in the ai-playground

## Usage
```
/count-projects
```

## Description
This utility command returns the number of projects currently in the ai-playground. It's primarily used internally by other scripts but can be useful for quick checks.

## Output
Returns a single number representing the count of project directories.

## Examples
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

## Related Commands
- `/list-projects` - Show detailed information about all projects
- `/init-playground` - Initialize the ai-playground structure