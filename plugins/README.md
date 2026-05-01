# Plugin bundling — deferred

The original plan called for bundling skills into 4 plugins (`warehouse`, `dbt-lifecycle`, `connections`, `workflows`). The hub has **22 skills** and **8 agents**. Plugin bundling is **deferred** until skill count crosses ~40.

## Why defer

Plugin value scales with:

- **Skill count** — bundling pays off as a navigation aid past 40 skills.
- **Distribution surface** — plugins shine when you ship to other teams via a marketplace.
- **Toggleability** — useful when groups of skills should ship/disable together.

For a personal hub at 22 skills with a single consumer, none of those payoffs are realized today. The cost (one-time refactor of 22 directories + path updates in any skill that references another skill by path) outweighs the win.

## What we'd do when the time comes

The intended bundling, kept here so future-you doesn't redesign it:

| Plugin | Contents |
|---|---|
| `warehouse` | `connection-bigquery`, `connection-snowflake`, `data-run-query`, `data-eda`, `data-browse`, `data-check-freshness` |
| `dbt-lifecycle` | `dbt-run`, `dbt-admin`, `model-new`, `model-research`, `model-document`, `model-build-metrics`, `model-run` |
| `connections` | `connection-github`, `connection-linear`, `connection-kb` |
| `workflows` | `workflow-notebook`, `workflow-troubleshoot-pipeline`, `setup-init`, `retrieve-memory`, `save-memory` |

Each would live at `plugins/<name>/skills/<skill-name>/SKILL.md` with a `plugins/<name>/.claude-plugin/plugin.json` manifest declaring name, version, description, and the agents/skills it owns.

## Triggers to revisit

Re-open this when:

- Skill count crosses 40 (current: 22).
- We start sharing the hub with another team.
- A skill needs versioning independent of the others.
