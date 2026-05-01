Use when the user asks to run or build a dbt model with the correct target, vars, and selector flags.

## Instructions

1. **Detect transformation framework** in the project directory:
   - `dbt_project.yml` → dbt

2. **Parse $ARGUMENTS** for: target name, model selector, and optional flags (e.g. `--full-refresh`).

3. **Read project config** to determine the correct variables and settings:
   - dbt: read `dbt_project.yml` for vars, `profiles.yml` for targets

4. **Construct and run the command**:
   - For GitHub Actions-hosted projects, prefer triggering runs via `gh`:
     - `gh workflow run` to trigger CI/CD workflows
     - `gh run list` to check status
     - `gh run view <run_id> --log-failed` to view job logs
   - For local runs, use the framework CLI:
     - dbt: `dbt run --select <model> --target <target> --vars '<vars>'`
   - If no model specified, run the full pipeline

   **If the run fails due to auth/credentials**: report the specific error and what access is needed.

5. **Parse results**:
   - dbt: read `target/run_results.json` for status, timing, errors

6. **Report**:
   - Models built successfully
   - Time elapsed
   - Any errors with the compiled SQL and suggested fix

Use $ARGUMENTS for target, model selector, and flags.
