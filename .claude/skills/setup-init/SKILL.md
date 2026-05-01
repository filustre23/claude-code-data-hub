Use when first setting up this hub or when the user asks how to configure their environment — interactively walks them through paths, credentials, and `.claude/settings.local.json`.

## Instructions

Walk the user through each step below conversationally. Ask one question at a time, confirm their answers, and build the final `settings.local.json` incrementally.

### Step 1: Project directories

Ask: "What project folders do you work in? Give me the paths (e.g., `~/Documents/my-dbt-project`)."

- Accept one or more paths
- Expand `~` for display but keep `~` in the config (it's resolved at runtime by hooks)
- These go into `permissions.additionalDirectories`

### Step 2: CLI authentication

Walk the user through authenticating with the services they need. Ask: "Which services do you need access to? (Select all that apply)"

- **BigQuery (GCP)**: `gcloud auth application-default login`
- **GitHub**: `gh auth login`
- **Linear**: Set `LINEAR_API_KEY` env var. Get a token from https://linear.app/settings/api
- **dbt Cloud** (optional): Set `DBT_CLOUD_API_TOKEN` and `DBT_CLOUD_ACCOUNT_ID` env vars. Get a token from dbt Cloud > Account Settings > API Access
- **Snowflake**: Set `SNOWFLAKE_*` env vars (`SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`)

For each selected service, guide them through the login command. Suggest they run each command with `! <command>` to execute it in the current session.

For Linear, help them add the env var to their shell profile (`~/.zshrc` or `~/.bashrc`):
```bash
export LINEAR_API_KEY="your-api-key-here"
```

For Snowflake, help them add the env vars to their shell profile:
```bash
export SNOWFLAKE_ACCOUNT="your_account"
export SNOWFLAKE_USER="your_user"
export SNOWFLAKE_PASSWORD="your_password"
export SNOWFLAKE_ROLE="your_role"
export SNOWFLAKE_WAREHOUSE="your_warehouse"
export SNOWFLAKE_DATABASE="your_database"
```

### Step 3: Write the file

Build and write `.claude/settings.local.json` with the collected values. Example output:

```json
{
  "permissions": {
    "additionalDirectories": [
      "~/Documents/my-dbt-project",
      "~/Documents/my-other-project"
    ]
  }
}
```

### Step 4: Confirm

Show the user the final file and confirm:
- "Your environment is set up. Next time you start a session, the first-time setup prompt won't appear."
- Remind them they can edit `.claude/settings.local.json` anytime or re-run `/setup-init` to start over.

## Rules

- Do NOT overwrite an existing `settings.local.json` without asking first — if one exists, show its current contents and ask if they want to reconfigure or just update specific fields.
- Keep the conversation concise — don't over-explain. One question per message.
- Validate that paths look reasonable (start with `~/` or `/`). Gently correct if the user gives a relative path.
