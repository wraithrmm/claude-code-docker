# Custom Command to Test and Fix A Codebase

## CRITICAL: Always Read Project-Specific Instructions First

## Goals

To run the tests for this project using the methods described in the project claude.md file and fix any failures.

## Workflow

1. Run the unit tests
2. Review the results for any failures and group them by their coverage to ensure that failures likely to be caused by common problems are run together. The goal is to prevent fixes for one group, impacting another group.
3. Using up to 5 sub-agents at any one time, start fixing bug without changing the tests themselves.
4. If there are any failures still remaining, return to step 1 and begin the process again.
