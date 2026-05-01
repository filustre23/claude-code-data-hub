Use when the user asks why a CI/CD pipeline failed, wants triage on the latest run, or needs help fixing a deploy. Pulls matching runbooks/post-mortems from the KB.

## Instructions

1. **Detect CI/CD platform** in the project directory:
   - If `.github/workflows/` exists → GitHub Actions (use `gh` CLI)

2. **Fetch recent pipeline runs**:
   - GitHub: `gh run list --limit 10`

3. **If $ARGUMENTS contains a run ID**, use that. Otherwise find the most recent failure.

4. **Fetch failed logs**:
   - GitHub: `gh run view <id> --log-failed`

5. **Match against KB runbooks and post-mortems** — extract a representative error signature (the most distinctive line from the failed log) and search:
   ```bash
   uv run python -c "
   import json
   from lib.kb.search import search
   results = search('<error signature from log>',
                    doc_types=['runbook', 'post_mortem'], limit=5)
   for r in results:
       print(f'[{r[\"similarity\"]:.3f}] {r[\"doc_type\"]:12} | {r[\"title\"]}')
       print(f'  {(r[\"content\"] or \"\")[:400]}')
   "
   ```
   If a runbook matches the failure mode, follow its diagnostic and fix steps before improvising. If a post-mortem describes the same incident, surface it to the user — they may be hitting a known recurrence.

6. **Detect transformation framework** in the project:
   - `dbt_project.yml` → dbt

7. **Classify the error**:
   - **Compile error**: SQL syntax, missing refs, Jinja errors
   - **Runtime error**: warehouse execution failure, permissions, timeouts
   - **Test failure**: uniqueness, not_null, recency, custom assertions
   - **Infrastructure**: auth failures, connection issues, OOM

8. **Read the relevant source file** that caused the failure.

9. **Output a structured diagnosis**:
   - **Status**: Pass/Fail
   - **Error type**: compile / runtime / test / infra
   - **Root cause**: what went wrong
   - **Relevant file**: path to the failing model/test
   - **Recommended fix**: specific action to take
   - **Next steps**: re-run, code change, full refresh, etc.

10. If a code fix is needed and the user approves, make the edit.

11. **If this incident is novel** (no runbook matched), propose ingesting one via `lib/kb/ingest/runbook.py` so the next person hits it gets the diagnostic + fix automatically. Same for `post_mortem` if it warranted full root-cause.

Use $ARGUMENTS for optional run ID.
