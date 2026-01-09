# Verify that a project has all required files.

## Usage
```
/verify-project <project-name>
```

## Description
This command checks if a project directory contains all the required files for a properly structured PRP. It's primarily used internally by other commands like `/continue-project`.

## Parameters
- `<project-name>`: The name of the project to verify

## Required Files
The command checks for these files in the project directory:
- `plan.md` - The project PRP document
- `progress.md` - Progress tracking log
- `status.json` - Project metadata
- `notes.md` - Additional notes and decisions

## Output Example
```
  ✅ plan.md exists
  ✅ progress.md exists
  ✅ status.json exists
  ✅ notes.md exists
```

Or if files are missing:
```
  ✅ plan.md exists
  ✅ progress.md exists
  
  ⚠️  Missing required files:
     - status.json
     - notes.md
```

## Exit Codes
- 0: Success (even if files are missing - this is just a verification tool)
- 1: Project directory not found

## Related Commands
- `/create-project` - Creates a project with all required files
- `/continue-project` - Continues a project (runs verify internally)