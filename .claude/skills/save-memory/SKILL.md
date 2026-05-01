Use when the user asks to save, remember, or persist context for a specific project (e.g. "/save-memory kanto-pokedex-pipeline", "remember this for the breeding tracker", "add to memory"). Append-only — never overwrites existing memory.

Pairs with `/retrieve-memory` for the read side.

## Usage

```
/save-memory <project> [--personal | --shared]
```

`<project>` is the directory name under `memory/` (or a new one to create). The flag is optional; if omitted, the skill asks.

## Instructions

1. **Parse `$ARGUMENTS`** for `<project>` and an optional `--personal` / `--shared` flag.
   - If `<project>` is missing, ask: "Which project? Available: <list-from-`ls memory/`>." Stop after asking.

2. **Determine the target tier**. If the flag is missing, ask:
   - **Shared** (`memory/<project>/PROJECT.md` in this repo, committed) — for context the whole team should know about.
   - **Personal** (`~/.claude/projects/.../memory/<project>/PROJECT.md`, gitignored) — for personal notes and preferences.
   - Recommend personal for anything that contains tokens, internal hostnames, or other secret-adjacent strings.

3. **Decide what to save**. Look at the recent conversation and propose a concise append. Default shape:
   ```markdown
   ## <Section header — pick from PROJECT.md template>

   - <bullet> — discovered <date>
   - <bullet>
   ```
   Match the existing template sections (`Stack`, `Key Models / Tables`, `Architecture Notes`, `Known Issues`, `Recent Changes`, `Contacts`). Don't invent new top-level sections unless the existing ones genuinely don't fit.

4. **Show the diff** to the user before writing:
   ```
   Will append to memory/<project>/PROJECT.md (or personal path):
   ─────────────────────────────────────
   <proposed content>
   ─────────────────────────────────────
   Approve? [y/n/edit]
   ```
   - `y` — append.
   - `n` — abort, no change.
   - `edit` — let them rewrite the proposed text inline.

5. **Secrets scrub**. Before writing to **shared** memory (committed), regex-scan the proposed content for:
   - API tokens (`(?i)(api[_-]?key|token|secret)[\s:=]+['\"]?[A-Za-z0-9_\-]{20,}`)
   - GitHub PATs (`ghp_[A-Za-z0-9]{36}`)
   - GCP service-account keys (`-----BEGIN PRIVATE KEY-----`)
   - AWS keys (`AKIA[0-9A-Z]{16}`)
   If matched, refuse to write to shared and offer the personal tier instead.

6. **Write append-only**:
   - **Shared**: ensure `memory/<project>/` exists (create if new), then append to `PROJECT.md`. If `PROJECT.md` doesn't exist, copy `memory/TEMPLATE.md` first, fill in `<Project Name>`, then append.
   - **Personal**: ensure `~/.claude/projects/<sanitized-cwd>/memory/<project>/` exists, append to `PROJECT.md` there.
   - **Never** delete or rewrite existing lines. If the new content contradicts an existing line, append the correction with a date marker; let the team review and reconcile.

7. **For shared writes**, print the staging command for the user:
   ```
   Saved. Stage with:
     git add memory/<project>/PROJECT.md
     git diff --cached memory/<project>/PROJECT.md
   ```
   Don't auto-commit. Memory updates ship with whatever PR triggered them.

8. **Optionally update the KB** (additive, asked-not-defaulted):
   - If the saved content is a generally-useful learning (a join recipe, a runbook, a region quirk), offer: "Also add this to the KB as a `<doc_type>` entry?"
   - If yes, route to `/kb-ingest`.

## Notes

- **Append-only is a hard rule.** Memory is a log, not a wiki. Lines age out via the user editing the file directly, never via this skill.
- The `SessionEnd` hook (`hooks/memory_consolidate.sh`) runs a similar flow automatically at session close, but with a stricter scope (transcript-only) and review gate.
- For a brand-new project, the skill creates the directory + `PROJECT.md` from `memory/TEMPLATE.md` on first save.
