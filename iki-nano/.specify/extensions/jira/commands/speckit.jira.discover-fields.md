---
description: "Discover Jira custom fields and suggest mapping configuration"
---

# Discover Jira Fields

Scan the Jira instance to find available fields (like Story Points or Sprints) and provide the necessary configuration snippets for Spec Kit.

## Prerequisites

- Ensure the Jira MCP server (default: `atlassian`) is active.
- Project key must be configured in `.specify/extensions/jira/jira-config.yml`.

## Execution

1. Load configuration from `.specify/extensions/jira/jira-config.yml`.
2. Use `mcp_jira_jira_search` with `action: "create_metadata"` and the configured `projectKey`.
3. Filter the results for relevant fields (e.g., fields containing "Point", "Sprint", "Estimate").
4. Present the discovered fields to the user.
5. Provide a YAML snippet they can copy into their `jira-config.yml` to map these fields.

## Output

A list of discovered custom fields with their Jira IDs and a suggested `custom_fields` configuration block.
