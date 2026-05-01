# CLAUDE.md

Personal Claude Code hub for working with Pokemon datasets — agents, skills, hooks, and a local ChromaDB knowledge base. Python 3.13 + `uv`.

## Setup

1. Fork & clone, then `ln -sf ../../hooks/check_no_secrets.sh .git/hooks/pre-commit`.
2. Launch `claude` from this directory. The `SessionStart` hook runs `git pull`, first-time-init, and `uv sync`.
3. Run `/setup-init` to configure your environment, or create `.claude/settings.local.json` (gitignored) with `permissions.additionalDirectories` pointing at your project folders.
4. Always launch Claude from this repo so skills and hooks load.
5. Seed the KB locally (one-time): `uv run python -m lib.kb.ingest.pokedex_entry && uv run python -m lib.kb.ingest.move_definition && uv run python -m lib.kb.ingest.region_quirk`.

## Knowledge Base (KB)

Single source of truth for Pokemon data context. Lives in **ChromaDB** (`PersistentClient` in `kb_data/`) — fully local, no cloud infra. Holds `table_summary`, `glossary_term`, `query_example`, `routing_rule`, `pokedex_entry`, `move_definition`, `region_quirk`, `join_recipe`, `post_mortem`, `runbook`, `freshness_sla`, `metric_definition`, `column_semantic`, `cross_skill_convention`, `qa_log`.

- Python: `lib/kb/` — `search()`, `get_context()`, `get_documents()`, `ping()`.
- Skill: `/connection-kb` (interactive) and `/kb-ingest` (curator-only).
- A `UserPromptSubmit` hook prepends top-3 KB hits before every prompt.

## Tenant Catalog

Structural metadata in `catalog/<region>.yml` (warehouse, datasets, tables, grain/partitioning). Resolution order: catalog → KB → dbt `profiles.yml` → ask user. See `catalog/CLAUDE.md` for details.

## Auto-Detection

- **Region**: `catalog/<region>.yml`
- **Transformation**: `dbt_project.yml`
- **Warehouse**: `bigquery` / `snowflake` / `duckdb` from `profiles.yml`
- **CI/CD**: `.github/workflows/`

## Agents

`leader` (orchestrator), `results-reporter` (synthesizer), `context-manager` (KB curator), `error-coordinator` (rollback owner), plus domain specialists (`data-engineer`, `data-scientist`, `analytics-engineer`, `data-analyst`). See `docs/orchestration.md` for the orchestration protocol.

## Skills

24 skills in `.claude/skills/`, prefixed by domain (`connection-`, `data-`, `model-`, `dbt-`, `setup-`, `workflow-`). Plus `/retrieve-memory` and `/save-memory`. See `docs/skills.md`.

## Memory

Two-tier (personal + shared). `/retrieve-memory <project>` and `/save-memory <project>`. SessionEnd hook proposes append-only diffs. See `docs/memory.md`.

## External Services

See `docs/external-services.md` for auth and MCP server setup.

## Commands

- `uv add <package>` — add dependency
- `uv sync` — sync env

## Reference

Files below are imported on demand (not loaded eagerly) — see Anthropic's CLAUDE.md `@`-import support:

- @docs/orchestration.md — sub-agent protocol, leader/reporter/context-manager/error-coordinator
- @docs/skills.md — skill discovery, KB pre-load points, plugin bundles
- @docs/memory.md — two-tier memory model, consolidation hook
- @docs/external-services.md — auth + MCP servers
