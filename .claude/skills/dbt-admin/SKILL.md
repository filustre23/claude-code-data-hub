Use when the user asks for dbt operations beyond the daily inner-loop — seeds, snapshots, package deps, source freshness, or anything dbt Cloud (jobs, runs, artifacts, cancel). For compile/run/build/test, prefer `/dbt-run`.

requires: [bigquery]

## Instructions

1. Parse `$ARGUMENTS` for the action and parameters.
2. For `deps`, `seed`, `snapshot`, or `source freshness` — use the dbt Core (CLI) commands below.
3. For dbt Cloud operations (`jobs`, `trigger`, `status`, `runs`, `artifacts`, `cancel`) — use the API patterns below.
4. If neither dbt Core nor dbt Cloud is configured, ask the user which they use.

## dbt Core (CLI) — operational tasks

### deps — Install packages
```bash
dbt deps
```
Reads `packages.yml` and installs dependencies to `dbt_packages/`.

### seed — Load CSV seed files
```bash
dbt seed [--select <seed_name>] --target <target>
```

### snapshot — Run snapshot models
```bash
dbt snapshot [--select <snapshot_name>] --target <target>
```

### source freshness — Check source data freshness
```bash
dbt source freshness --target <target> [--select <source_name>]
```
Parse `target/sources.json` for status (pass/warn/error). Show last loaded timestamp + threshold.

## dbt Cloud (API)

### Setup

- **API token**: `DBT_CLOUD_API_TOKEN` env var (service or user token from dbt Cloud → Account Settings → API Access).
- **Account ID**: `DBT_CLOUD_ACCOUNT_ID` env var (visible in URL: `cloud.getdbt.com/deploy/<account_id>/...`).
- **Base URL**: `https://cloud.getdbt.com/api/v2/accounts/$DBT_CLOUD_ACCOUNT_ID`.
- Optionally `DBT_CLOUD_PROJECT_ID` to skip project selection.

### Auth header
```
-H "Authorization: Token $DBT_CLOUD_API_TOKEN" -H "Content-Type: application/json"
```

### Actions

#### jobs — List available jobs
```bash
curl -s "$BASE_URL/jobs/?project_id=<project_id>" \
  -H "Authorization: Token $DBT_CLOUD_API_TOKEN"
```
Show job name, ID, schedule, environment, last run status.

#### trigger — Trigger a job run
```bash
curl -s -X POST "$BASE_URL/jobs/<job_id>/run/" \
  -H "Authorization: Token $DBT_CLOUD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"cause": "Triggered via Claude Code"}'
```
Ask the user for the job ID, or run `jobs` first to find it. Returns a `run_id` for status tracking.

#### status — Check a run's status
```bash
curl -s "$BASE_URL/runs/<run_id>/" \
  -H "Authorization: Token $DBT_CLOUD_API_TOKEN"
```
Parse `status_humanized` (Queued, Starting, Running, Success, Error, Cancelled). Show duration, trigger cause, git branch.

#### runs — List recent runs
```bash
curl -s "$BASE_URL/runs/?job_definition_id=<job_id>&limit=10&order_by=-finished_at" \
  -H "Authorization: Token $DBT_CLOUD_API_TOKEN"
```

#### artifacts — Fetch run artifacts
```bash
curl -s "$BASE_URL/runs/<run_id>/artifacts/<path>" \
  -H "Authorization: Token $DBT_CLOUD_API_TOKEN"
```
Common paths:
- `run_results.json` — model run statuses + timing
- `manifest.json` — full project manifest (models, tests, sources)
- `catalog.json` — column-level metadata
- `sources.json` — source freshness results

#### cancel — Cancel a running job
```bash
curl -s -X POST "$BASE_URL/runs/<run_id>/cancel/" \
  -H "Authorization: Token $DBT_CLOUD_API_TOKEN"
```

## If auth fails

- **dbt Core**: see `/dbt-run` `debug` action.
- **dbt Cloud**: verify env vars set. Test:
  ```bash
  curl -s "https://cloud.getdbt.com/api/v2/accounts/$DBT_CLOUD_ACCOUNT_ID/" \
    -H "Authorization: Token $DBT_CLOUD_API_TOKEN"
  ```

Use $ARGUMENTS for the action and parameters.
