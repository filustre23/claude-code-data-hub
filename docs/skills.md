# Skills

Skills live in `.claude/skills/` as slash commands. Each skill is a directory containing a `SKILL.md` file. The skill name = directory name = slash command (e.g. `connection-bigquery/SKILL.md` → `/connection-bigquery`).

## Prefix conventions

- `connection-` — External service access (BigQuery, Snowflake, GitHub, Linear, KB)
- `data-` — Query and analyze data (EDA, run queries, check freshness, browse catalog)
- `model-` — Work on transformation models (document, scaffold, run, research, lineage, metrics)
- `setup-` — Environment setup (init wizard)
- `workflow-` — Orchestration and workflows (notebooks, troubleshoot pipelines)

Two memory skills (`/retrieve-memory`, `/save-memory`) live at the root of `.claude/skills/` since they cross-cut all prefixes.

## How sub-agents discover skills

Sub-agents discover and choose their own skills at runtime:

1. Read `.claude/skills/` to discover available skills.
2. Evaluate which skill(s) match the task at hand. The first line of each `SKILL.md` is a trigger phrase ("Use when user asks to ...") — match against that.
3. Follow the matching skill's instructions to execute the task.
4. If no existing skill fits the task:
   - Proceed with best judgment to complete the task.
   - Search online for well-regarded community skills (e.g., `awesome-claude-code-subagents`, `awesome-claude-code-toolkit`).
   - If a quality community skill is found and the task pattern is likely to recur, propose saving it to `.claude/skills/` for future use.
   - Only suggest saving skills that would genuinely smooth future workflows.

## KB pre-load points

Skills that operate on data should call `lib.kb.search()` or `lib.kb.get_context()` in their prelude to load relevant Pokemon/domain context before generating SQL or analyzing tables. The `UserPromptSubmit` hook also prepends top-3 KB hits before any skill runs.

## Plugin bundles

Skills are bundled into plugins under `plugins/`:

- `plugins/warehouse/` — connection-bigquery, connection-snowflake, data-* skills
- `plugins/dbt-lifecycle/` — model-* skills, dbt-run, dbt-admin
- `plugins/connections/` — connection-github, connection-linear, connection-kb
- `plugins/workflows/` — workflow-* skills, setup-init, retrieve-memory, save-memory
