---
description: "Synchronize current spec and tasks to Jira issues"
---

# Jira Sync

Synchronize the local specification and tasks with Jira issues. This command creates Epics, Stories, and Tasks/Sub-tasks based on the content of `spec.md` and `tasks.md`.

## Prerequisites

- Active Jira MCP server.
- Configured project key in `.specify/extensions/jira/jira-config.yml`.
- A feature must be active (path resolved in `.specify/feature.json`).

## Mapping Logic

- **spec.md** -> Jira **Epic**
- **Phase Headers** in `tasks.md` -> Jira **Stories** (linked to the Epic)
- **Task Items** in `tasks.md` -> Jira **Tasks** or **Sub-tasks** (linked to the Story)

## Execution Flow

1. **Locate Feature**: Read `.specify/feature.json` to get the current `feature_directory`.
2. **Read Files**:
   - Read `spec.md` for Epic details.
   - Read `tasks.md` for Story and Task details.
3. **Load Mapping**: Check if `SPECIFY_FEATURE_DIRECTORY/jira-mapping.json` exists. This file tracks the link between local items and Jira keys.
4. **Create/Update Issues**:
   - For the Spec: Create or update an Epic.
   - For each Phase: Create or update a Story linked to the Epic.
   - For each Task: Create or update a Task/Sub-task linked to the Phase's Story.
5. **Update Mapping**: Save the issue keys back to `SPECIFY_FEATURE_DIRECTORY/jira-mapping.json`.

## Issue Links

- Stories should have the Epic Link field set to the Epic's key.
- Tasks/Sub-tasks should have the Parent field set to the Story's key (if using Sub-tasks) or a Link (if using regular Tasks).

## Output

A summary of created or updated Jira issues with links to the Jira project.
