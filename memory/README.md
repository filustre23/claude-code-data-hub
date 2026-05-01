# Project memory

Context that should survive across Claude Code sessions. Two tiers:

| Tier | Path | Git | Use for |
|------|------|-----|---------|
| **Shared** | `memory/<project>/PROJECT.md` (this dir) | Committed | Project context — architecture, key models, gotchas |
| **Personal** | `~/.claude/projects/.../memory/<project>/` | Gitignored (local only) | Personal preferences, sensitive notes |

## Skills

- `/retrieve-memory <project>` — load both tiers + recent KB Q&A.
- `/save-memory <project>` — append-only write, prompts shared-vs-personal, secrets scrub before writing to shared.

## Auto-consolidation

A `SessionEnd` hook (`hooks/memory_consolidate.sh`) runs at session close. It examines the transcript, proposes append-only diffs to the relevant `memory/<project>/PROJECT.md`, and prints them for review. The hook is **append-only** — never overwrites, never deletes. The user manually `git add`s after reviewing.

`autoMemoryEnabled` is `false` by default — review-gated consolidation is preferred over Anthropic's full auto-memory.

## Secrets guardrails

The hook (and `/save-memory`) regex-scan proposed shared content for API tokens, GitHub PATs, GCP service-account keys, and AWS keys before writing. A match routes the content to personal memory instead of shared.

## Adding a new project

The first `/save-memory <new-project>` call creates `memory/<new-project>/PROJECT.md` from `memory/TEMPLATE.md`. No need to bootstrap manually.

## Conventions

- One directory per project. Subprojects/tasks get their own dir with multi-file context.
- `PROJECT.md` is the index. Other `.md` files in the directory are loaded too — split when one file gets unwieldy.
- Append, don't rewrite. Memory is a chronological log; corrections append with a date marker.
- Sub-agents working on a known project should call `/retrieve-memory <project>` (or read the files directly) before starting.
