# Project Memory

Project-specific memory lives in `memory/<project_name>/PROJECT.md`. These are not auto-initialized — only create or read them when the user explicitly asks to save or recall project memory.

## Two-tier model

- **Personal memory** (`~/.claude/projects/.../memory/`) — for the user's own notes, preferences, and context that only they need. Never committed.
- **Shared memory** (`memory/<project_name>/PROJECT.md` in this repo) — for project context the whole team should know about.

## How to save and recall

- **Save**: `/save-memory <project>` — append-mode helper. Prompts shared-vs-personal, opens an editor diff, never auto-rewrites.
- **Recall**: `/retrieve-memory <project>` — reads `memory/<project>/PROJECT.md` and any sibling files. Falls back to personal memory if shared file missing. Lists available projects on miss.

## Auto-consolidation

A `SessionEnd` hook (`hooks/memory_consolidate.sh`) examines the transcript at session end and proposes append-only diffs to relevant `memory/<project>/PROJECT.md`. The hook:

- Is append-only — never overwrites or deletes existing lines.
- Has a secrets scrub guard — never writes to shared `memory/` if the transcript contains secret-like patterns.
- Prints the proposed diff to stdout for review. The user must commit it manually (`git add` + `git commit`).

`autoMemoryEnabled` remains `false` — review-gated memory writes are preferred over full automation.

## For sub-agents

When working on a specific project, always read `memory/<project_name>/PROJECT.md` first (if it exists) to load project context before starting work. This applies to all agents and sub-agents operating in this repo.
