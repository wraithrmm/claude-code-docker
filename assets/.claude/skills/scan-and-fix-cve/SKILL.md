---
name: scan-and-fix-cve
description: Analyse and fix CVE vulnerabilities in Docker images. Use when asked to address CVE failures, fix security scan results, or remediate vulnerabilities.
disable-model-invocation: true
argument-hint: [path-to-cve-report]
---

## CRITICAL: Always Read Project-Specific Instructions First

Before doing anything, read `/workspace/project/CLAUDE.md` for project-specific scan commands and Dockerfile locations.

## Workflow

1. Use the `fix-cve` skill to drive the process.
2. If a CVE report path is provided in `$ARGUMENTS`, use that report.
3. If no report is provided, run the project's Docker image security scans (as documented in the project CLAUDE.md) to produce a report.
4. Follow the `fix-cve` skill workflow: break down each CVE, research online, cross-reference, use agent teams, implement fixes, then build and scan to confirm.
