# Orchestration Protocol

For complex or multi-step tasks (anything requiring 2+ sub-agents or multiple skills), follow this flow.

## Step 1: Leader Agent (the "init")

1. Spawn the `leader` agent, passing the user's full request.
2. Receive the structured execution plan (phases, sub-agent types, parallel vs sequential).
3. Present the plan to the user and wait for approval before proceeding.
4. If the user requests changes, re-invoke the leader with the feedback.

The leader has named partnerships with two specialized orchestrators:

- `context-manager` — KB curator. Owns ChromaDB collection writes, glossary maintenance, ingest cadence, and dedupe. Invoke it when a task involves updating, expanding, or auditing the knowledge base.
- `error-coordinator` — Rollback owner. Invoke it when an action phase fails and downstream sub-agents depend on the failed work.

## Step 2: Execute (Sub-agents do the work)

1. Follow the plan's phase structure:
   - **Parallel phases**: spawn all sub-agents in the phase simultaneously.
   - **Sequential phases**: spawn sub-agents one at a time, passing prior results as context.
2. Each sub-agent discovers and chooses its own skill from `.claude/skills/` at runtime.
3. **Parallel safety**: sub-agents in parallel phases must NOT create or modify shared files (`.claude/skills/`, `memory/`). They should propose new skills or memory updates in their output instead — the results-reporter collects these.
4. **Rollback on failure**: if a sub-agent in an action phase fails, check the plan's rollback strategy before continuing. If subsequent sub-agents depend on the failed one, halt the phase and report to the user rather than proceeding with bad state.
5. Collect all sub-agent responses.

## Step 3: Results Reporter (the "done")

1. Once all sub-agents have reported back, spawn the `results-reporter` agent.
2. Pass it: the original plan + all sub-agent results.
3. Present the compiled output to the user.

## When to skip orchestration

- Simple single-skill tasks (e.g. "research the trainer_team model" → just use `/model-research` directly).
- Quick questions that need no sub-agents.
- The user explicitly says "just do it" or similar.

## Sub-agent Types

The leader assigns one of these types per unit of work:

- **general-purpose** — Full-capability agent for action-oriented work (scaffolding, fixing, building).
- **Explore** — Fast, read-only agent for research tasks (finding files, searching code, answering codebase questions).
- **Plan** — Read-only architect agent for designing implementation strategies.
