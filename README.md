# Claude Code Data Hub

Public Claude Code launchpad for data work. Launch Claude from this repo and work on your projects via `additionalDirectories`. Ships with a Pokemon-themed example dataset (catalog + KB seeds + memories) so you can see the pieces wired together — **swap that out for your own domain on day one**.

## Make it yours

The Pokemon framing is example data, not the point. After cloning, ask Claude to adapt the hub to your stack — for example:

> "Read the repo, then convert the catalog, KB seeds, and memories from the Pokemon example to my stack: warehouse `<bigquery|snowflake|duckdb>` at project `<your-project>`, domain `<healthcare claims | e-commerce orders | ad-tech impressions | ...>`. Replace `catalog/kanto.yml` and `catalog/johto.yml` with my real datasets, rewrite `lib/kb/ingest/*.py` for my doc types, and reseed `memory/*` with my actual projects."

Claude will read the existing structure and propose a diff. The framework (orchestration, skills, hooks, ChromaDB KB, two-tier memory) is domain-agnostic; only the example content needs replacing.

## Quick Start

1. Clone the repo and `cd` into it
2. Run `ln -sf ../../hooks/check_no_secrets.sh .git/hooks/pre-commit`
3. Run `uv sync` to install dependencies
4. Launch `claude`
5. Approve the shared hooks when prompted
6. Run `/setup-init` — the interactive wizard will configure your project directories and any service auth you need (BigQuery, GitHub, Linear, Snowflake)
7. Seed the local KB (these are the example seeds — replace with your own):
   ```
   uv run python -m lib.kb.ingest.pokedex_entry
   uv run python -m lib.kb.ingest.move_definition
   uv run python -m lib.kb.ingest.region_quirk
   ```

## Mental Model

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   YOU (the human)                                               │
│   $ claude                                                      │
│                                                                 │
└────────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   AGENT (the main Claude session)                               │
│                                                                 │
│   This is what you're talking to. It reads CLAUDE.md,           │
│   settings.json, and memory on startup. It has full access      │
│   to tools (Read, Edit, Write, Bash, Glob, Grep, etc).          │
│                                                                 │
│   It can do work directly, or delegate to sub-agents.           │
│                                                                 │
└───────┬──────────────────────┬──────────────────────────────────┘
        │                      │
        │ spawns               │ invokes directly
        ▼                      ▼
┌────────────────┐    ┌────────────────────────────────────────┐
│                │    │                                        │
│  SUB-AGENTS    │    │  SKILLS (slash commands)               │
│                │    │                                        │
│  .claude/      │    │  .claude/skills/*/SKILL.md             │
│  agents/*/AGENT.md  │    │                                        │
│                │    │  The agent can invoke skills directly  │
│  Autonomous    │    │  (e.g. /model-research) without needing│
│  workers that  │    │  a sub-agent for simple tasks.         │
│  the agent     │    │                                        │
│  delegates to. │    └────────────────────────────────────────┘
│                │
│  Each has:     │
│  • a name      │
│  • a model     │
│  • tools       │
│  • a prompt    │
│                │
└───────┬────────┘
        │
        │ sub-agents discover and use
        ▼
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│  SKILLS (again — but now used by sub-agents)                   │
│                                                                │
│  .claude/skills/*/SKILL.md                                     │
│                                                                │
│  Sub-agents read this directory at runtime to find the right   │
│  playbook for their task. Skills are reusable instructions     │
│  that any sub-agent can follow.                                │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Key Distinctions

```
Agent vs Sub-agent
├── Agent = the main Claude session you're talking to
└── Sub-agent = a spawned worker process with its own context
    └── defined in .claude/agents/*/AGENT.md
    └── has its own model, tools, and prompt
    └── runs autonomously, returns results to the agent

Sub-agent vs Skill
├── Sub-agent = WHO does the work (an autonomous actor)
└── Skill = HOW to do the work (a playbook / instructions)
    └── a sub-agent reads a skill to know what steps to follow
    └── skills are reusable across any sub-agent

Sub-agent types vs Sub-agent definitions
├── Types = built-in Claude Code types (general-purpose, Explore, Plan)
│   └── determine the sub-agent's capabilities and tools
└── Definitions = .claude/agents/*/AGENT.md files
    └── provide domain knowledge, behavior, and specialized prompts
    └── run on top of a type
```

### What Lives Where

```
.claude/
├── agents/
│   └── <name>/AGENT.md      ← Sub-agent definitions (discovered dynamically)
├── skills/
│   └── <prefix>-<name>/SKILL.md  ← Skill definitions (slash commands)
├── settings.json            ← Shared settings (hooks, statusLine)
└── settings.local.json      ← Personal settings (additionalDirectories)

memory/
└── <project>/PROJECT.md     ← Shared project memory (committed)
hooks/                       ← Hook scripts (uv_auto_add.sh, kb_prelude.sh)
lib/kb/                      ← ChromaDB-backed knowledge base
kb_data/                     ← Local chroma persistence dir (gitignored)
```

## Orchestration Flow

For complex or multi-step tasks, the agent uses orchestration:

```
You → Agent → spawns leader sub-agent
                → leader creates plan
                → agent presents plan to you
                → you approve
                → agent spawns worker sub-agents (parallel/sequential)
                → each worker discovers its own skill
                → agent spawns results-reporter sub-agent
                → compiled results → you
```

For simple tasks, the agent skips orchestration:

```
You → Agent → invokes skill directly (or spawns 1 sub-agent) → response
```

## Examples

### Simple Task (skips orchestration)

> **User**: "research the trainer_team model in kanto"

```
User: "research the trainer_team model in kanto"
  │
  ▼
Agent loads memory/kanto-pokedex-pipeline/PROJECT.md for project context
  → reads .claude/skills/
  → matches /model-research
  → auto-detects dbt + BigQuery from profiles.yml
  → reads trainer_team.sql + schema.yml + upstream refs
  │
  ▼
User gets structured model briefing:
  "trainer_team is a core model in prod/models/core/ that
   consolidates Kanto trainer rosters, gym badges earned,
   and current party composition into a single analytics-
   ready table..."
```

### Direct Work (agent does it itself)

> **User**: "show me encounter counts by route for kanto"

```
User: "encounter counts by route for kanto"
  │
  ▼
Agent loads memory/kanto-pokedex-pipeline/PROJECT.md
  → detects BigQuery target, kanto dataset
  → reads model schemas to find encounter/route tables
  → writes and runs SQL via bq CLI
  │
  ▼
User gets formatted results + the SQL for future use
```

### Complex Task (full orchestration)

> **User**: "the kanto daily incremental run failed, figure out why and fix it"

```
User: "kanto daily incremental failed, fix it"
  │
  ▼
Agent loads memory/kanto-pokedex-pipeline/PROJECT.md
  → recognizes this is complex (research + action) → spawns leader sub-agent

━━━ STEP 1: LEADER (init) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Leader classifies as Hybrid, creates execution plan:

  ## Execution Plan
  **Type**: Hybrid
  **Estimated sub-agents**: 4

  ### Phase 1: Diagnose [parallel]
  ├── Sub-agent 1.1: Freshness Check
  │   Type: Explore — check table freshness on kanto_staging.__TABLES__
  │
  ├── Sub-agent 1.2: GHA Troubleshooting
  │   Type: Explore — diagnose latest failure with gh run view --log-failed
  │
  └── Sub-agent 1.3: Model Research
      Type: Explore — research affected models in prod/models/

  ### Phase 2: Fix [sequential, depends on Phase 1]
  └── Sub-agent 2.1: Apply Fix
      Type: general-purpose — fix root cause

  ### Rollback Strategy
  - git checkout modified files if the fix makes things worse

Agent presents plan → User approves

━━━ STEP 2: EXECUTE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1 runs in parallel:
  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
  │ /data-check-    │ │ /workflow-      │ │ /model-research │
  │  freshness      │ │  troubleshoot-  │ │                 │
  │ Queries         │ │  pipeline       │ │ Reads models in │
  │ kanto_staging   │ │ gh run view     │ │ prod/models/    │
  │ .__TABLES__     │ │ --log-failed    │ │ core/ staging/  │
  │ for staleness   │ │ finds error     │ │ int/ production │
  └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
           │                   │                    │
           └───────────┬───────┘────────────────────┘
                       ▼
Phase 2 runs sequentially:
  Sub-agent 2.1 reads Phase 1 results
  → Root cause: NULL handling bug in int_pokemon_level_stats
  → Fixes the SQL, compiles with:
    dbt compile --select int_pokemon_level_stats
    --target kanto

━━━ STEP 3: RESULTS REPORTER (done) ━━━━━━━━━━━━━━━━━━━━━━━━━━

  ## Research Summary
  - kanto daily incremental failed at int_pokemon_level_stats
  - Root cause: NULL handling on optional held_item field
  - kanto_staging tables last updated during prior successful run

  ## What Was Done
  - [done] Fixed NULL coalesce in int_pokemon_level_stats.sql
  - [done] Compiled successfully against kanto target

  ## Verification Checklist
  - [ ] Re-run dbt: dbt run --select int_pokemon_level_stats+ --target kanto
  - [ ] Check downstream models refresh correctly
  - [ ] Verify row counts in kanto_staging tables
```
