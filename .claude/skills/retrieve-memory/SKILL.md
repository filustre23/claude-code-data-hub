Use when the user asks to recall, retrieve, or load saved context for a specific project (e.g. "/retrieve-memory kanto-pokedex-pipeline", "what do we know about the johto breeding tracker", "load memory for the gym leader analytics").

Loads the team-shared memory for `<project>` from `memory/<project>/` plus any personal memory the user has under `~/.claude/projects/.../memory/`. Pairs with `/save-memory` for the write side.

## Usage

```
/retrieve-memory <project>
```

`<project>` is the directory name under `memory/` (e.g. `kanto-pokedex-pipeline`, `johto-breeding-tracker`).

## Instructions

1. **Parse `$ARGUMENTS`** for the project name. If empty or only whitespace, list available projects:
   ```bash
   ls -1 memory/ | grep -v '^TEMPLATE\.md$' | grep -v '^README\.md$' | grep -v '^\.'
   ```
   Tell the user: "Which project? Available: <list>. Run `/retrieve-memory <project>`."
   Then stop.

2. **Validate the project exists**. If `memory/<project>/` doesn't exist:
   - List available projects (same command as step 1).
   - Suggest `/save-memory <project>` to create one.
   - Stop.

3. **Load shared memory** (the primary source):
   - Read `memory/<project>/PROJECT.md` if present.
   - Read every other `.md` file in `memory/<project>/` (some projects have multi-file context).
   - Order: `PROJECT.md` first, then the rest alphabetically.

4. **Load personal memory** if present:
   - Compute the personal path: `~/.claude/projects/<sanitized-cwd>/memory/<project>/`. The sanitization rule maps `/` to `-` and trims leading/trailing dashes. (Claude Code uses this same convention for autoMemoryDirectory.)
   - If that directory exists, read its `.md` files too.
   - **Mark personal sections clearly** in the output — they're for the current user only.

5. **Pull recent project Q&A from the KB** (additive, optional):
   ```python
   from lib.kb import search
   results = search(f"project:{project} recent context", doc_types=["qa_log"], project=project, limit=5)
   ```
   Soft-fail on KB unreachability — the file-system memory is the source of truth.

6. **Render**: emit a structured load with section headers per file:
   ```
   ## Loaded memory for <project>

   ### memory/<project>/PROJECT.md
   <contents>

   ### memory/<project>/<other-file>.md
   <contents>

   ### Personal notes (~/.claude/...)
   <contents>

   ### Recent KB Q&A (project=<project>)
   <bulleted list of qa_log titles + similarity scores>
   ```

7. **Print a one-liner footer** so the user knows what was loaded:
   `Loaded N file(s) from shared memory, M file(s) from personal memory, K Q&A entries from KB.`

## Notes

- This skill is **read-only**. To update memory, the user runs `/save-memory <project>` (companion skill) or commits to `memory/<project>/PROJECT.md` directly.
- For sub-agents: at the start of any task scoped to a known project, call this skill (or read the same files directly) before doing anything else.
- If multiple projects could match a fuzzy query (e.g. "kanto" vs "kanto-pokedex-pipeline"), prefer the exact directory match. If still ambiguous, ask.
- Never display personal memory in a context that will be committed — it's `.gitignore`d for a reason.
