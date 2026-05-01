Use when the user asks to compile, run, build, or test dbt models — the daily inner-loop. For deps/seed/snapshot/source-freshness or dbt Cloud job ops, prefer `/dbt-admin`.

requires: [bigquery]

## Instructions

1. Detect the dbt environment (Setup detection below).
2. Parse `$ARGUMENTS` for the action (compile, run, build, test, ls, debug) and selectors.
3. Run the matching action with the right target and vars.
4. Format the output per the patterns below.

## Setup detection

- Read `dbt_project.yml` for project name, profile, vars, and model paths.
- Read `profiles.yml` for targets, GCP project, dataset, and auth method.
- If a virtual environment exists (`.venv/`, `venv/`), use `dbt` from it; otherwise system `dbt`.
- If `dbt_project.yml` is missing, ask the user where the dbt project lives — don't guess.

## Actions

### compile — Compile SQL without executing
```bash
dbt compile --select <model_or_selector> --target <target> [--vars '<json>']
```
Show the compiled SQL from `target/compiled/`. Best first step when debugging Jinja or verifying generated SQL before a real run.

### run — Build models
```bash
dbt run --select <model_or_selector> --target <target> [--vars '<json>'] [--full-refresh]
```
- If no `--select`, runs the full project — confirm with the user first.
- If `--full-refresh`, warn that incremental models will be rebuilt from scratch.
- Parse `target/run_results.json` for status, timing, row counts, errors.

### build — Run + test in DAG order
```bash
dbt build --select <model_or_selector> --target <target> [--vars '<json>']
```
Combines `run`, `test`, `snapshot`, `seed` in correct dependency order. Use this for a full rebuild loop.

### test — Run data tests
```bash
dbt test --select <model_or_selector> --target <target>
```
For failures, show the failing test query and a sample of failing rows from `target/run_results.json`.

### ls — List resources matching a selector
```bash
dbt ls --select <selector> --resource-types model test source [--output json]
```
Verify selectors before invoking `run`/`build`/`test`.

### debug — Validate connection and config
```bash
dbt debug --target <target>
```
Run this first when troubleshooting connection issues. Checks `profiles.yml`, `dbt_project.yml`, warehouse connectivity, and dependencies.

## Selectors cheat sheet

- Single model: `model_name`
- Model + downstream: `model_name+`
- Model + upstream: `+model_name`
- Full lineage: `+model_name+`
- By path: `path:models/staging/`
- By tag: `tag:daily`
- By config: `config.materialized:incremental`
- Exclude: `--exclude model_name`

## Output formatting

- **Run/build results**: table with model name, status, execution time, rows affected.
- **Test results**: table with test name, status, failure count.
- **Errors**: show the compiled SQL, error message, and a suggested fix.

## If auth fails

Run `dbt debug --target <target>` to diagnose. Common issues:
- Missing `profiles.yml` — check `~/.dbt/profiles.yml` or project-local path.
- GCP auth expired — run `gcloud auth application-default login`.
- Wrong target — list available targets from `profiles.yml`.

Use $ARGUMENTS for the action and parameters.
