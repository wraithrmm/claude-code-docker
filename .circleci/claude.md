# CircleCI Coding Guidelines

## Overview

This file provides guidance for building efficient CircleCI pipelines. When changes are pushed to the GIT Repository, CircleCI triggers the build process defined in `config.yml`.

## Important Documentation

For CircleCI documentation, see:
https://circleci.com/docs/

## Workflow Optimization Patterns

### 1. Parallel Job Execution
Identify jobs that can run concurrently to reduce total pipeline time.

**Key Principle**: Jobs should only have dependencies (`requires`) when they actually need outputs from previous jobs or when there's a logical sequence requirement.

If you are unclear when if if one job should be blocked on the success of another, then you should asked the user.

### 2. Sequential vs Parallel Decision Matrix

| Job Type | Can Run in Parallel? | Typical Dependencies |
|----------|---------------------|---------------------|
| Unit Tests | Yes | None (only checkout) |
| Integration Tests | Yes | None (only checkout) |
| Build/Compile | Yes | None (only checkout) |
| Security Scans | No | Requires built artifacts |
| Publishing/Deploy | No | Requires all validations |

## Performance Best Practices

### 1. Workspace Persistence
Use workspaces to share data between jobs instead of rebuilding:

```yaml
# In build job:
- persist_to_workspace:
    root: /tmp/workspace
    paths:
      - image.tar
      - tag.txt

# In subsequent jobs:
- attach_workspace:
    at: /tmp/workspace
```

### 2. Docker Layer Caching
Always enable for Docker builds:

```yaml
- setup_remote_docker:
    docker_layer_caching: true
```

## Common Pipeline Patterns

### 1. Standard Docker Build Pipeline
```
┌──────┐  ┌───────┐
│ test │  │ build │  (Parallel execution)
└───┬──┘  └───┬───┘
    │     ┌───▼───┐
    │     │ scan  │  (Only waits for build)
    │     └───┬───┘
    └────────┬┘
         ┌───▼─────┐
         │ publish │ (Waits for everything)
         └─────────┘
```

## Pipeline Analysis Checklist

When optimizing a CircleCI pipeline:

1. **Identify Independent Jobs**: Which jobs don't depend on each other's outputs?
2. **Check Data Dependencies**: Which jobs produce artifacts needed by others?
3. **Check Permission Dependencies**: Which jobs should not happen if other jobs (like tests) fail?
4. **Review Resource Usage**: Are jobs using appropriate executors?
5. **Validate Caching**: Is Docker layer caching enabled? Are workspaces used efficiently?
6. **Minimize Redundancy**: Is code checked out multiple times unnecessarily?

## Example Optimization

**Before** (Sequential - Slower):
```yaml
- test:
- build:
    requires: [test]
- scan:
    requires: [build]
```

**After** (Parallel - Faster):
```yaml
- test:
- build:
- scan:
    requires: [build]  # Only needs the built image
- publish:
    requires: [test, scan]  # Ensures all validations pass
```

This change allows test to run completely independently while scan processes the built image, reducing total pipeline time, but not publishing images with bugs.

## Debugging Tips

1. **Request a Pipeline Visualization from the User**: CircleCI provides a visual workflow diagram
2. **Check Job Timing**: Look for bottlenecks in the slowest jobs
3. **Monitor Queue Time**: High queue times might indicate resource constraints
4. **Review Failed Jobs**: Check if failures are due to missing dependencies

## Best Practices Summary

1. **Parallelize when possible** - Run independent jobs concurrently
2. **Use workspaces** - Share artifacts between jobs efficiently  
3. **Enable caching** - Docker layer caching and dependency caching
4. **Minimize redundancy** - Checkout and build only when necessary
5. **Follow conventions** - Use established patterns and contexts
6. **Document changes** - Explain non-obvious workflow decisions