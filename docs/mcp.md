# MCP servers

Three MCP servers are declared in `.mcp.json`. They are **disabled by default** until explicitly enabled in your `.claude/settings.local.json` — running an MCP server pulls a tool list into context (50k+ tokens if you're not careful) and you should opt in deliberately.

## How to enable

In `.claude/settings.local.json`:

```json
{
  "enabledMcpjsonServers": ["dbt", "google-data-toolbox", "linear"]
}
```

Or pick a subset. See `.mcp.json` for the full list and Anthropic's [MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp) for permission semantics.

## Servers

### `dbt` — official dbt Labs MCP server

**What**: live access to dbt Cloud jobs/runs/manifests + dbt Core CLI.

**Setup**:
1. `uv tool install dbt-mcp` (or trust `uvx` to fetch on first run).
2. Set env vars in your shell or `.claude/settings.local.json`:
   - `DBT_PROJECT_DIR` — path to your dbt project
   - `DBT_PROFILES_DIR` — usually `~/.dbt`
   - `DBT_CLOUD_API_TOKEN` — for Cloud access (skip if Core-only)
   - `DBT_CLOUD_ACCOUNT_ID` — visible in the dbt Cloud URL

**Replaces**: shell-out in `connection-dbt`/`dbt-run`/`dbt-admin` for live job queries. The skills become methodology wrappers ("how to interpret a run_results.json", "what selector to use") and call the MCP for execution.

### `google-data-toolbox` — Google MCP Data Toolbox

**What**: unified BigQuery + Postgres tool surface, configured via `tools.yaml`.

**Setup**:
1. Install: see https://github.com/googleapis/genai-toolbox (typically a single `toolbox` binary).
2. Author a `tools.yaml` at the repo root listing the exact tools you want exposed (helps avoid the 50k-token tool-list bloat).
3. Auth flows through `gcloud auth application-default login` (same as the existing skills).

**Replaces**: shell-out in `connection-bigquery` for query/fetch. Schema-browsing and admin operations stay in the skills.

### `linear` — Linear MCP server

**What**: native MCP for Linear issues, projects, teams, comments.

**Setup**:
- `LINEAR_API_KEY` env var (already used by `connection-linear`).
- `npx` will pull the server on first invocation.

**Replaces**: curl+GraphQL boilerplate in `connection-linear`. The skill keeps the "how to find the right team" methodology; transport moves to MCP.

## Verifying

Once enabled:

```bash
claude mcp list
```

Should show all enabled servers with green status. If a server hangs, run with `--mcp-debug` to see what it's trying to do.

## Why opt-in instead of always-on

- **Context budget**: each MCP exposes 5–50 tools to Claude. Tool definitions cost tokens on every prompt. Anthropic's Tool Search (released 2026) reduces this by ~85% but it's still meaningful for a hub with 24 skills already in the listing.
- **Auth scope creep**: the dbt MCP wants `DBT_CLOUD_API_TOKEN`; the Google toolbox wants gcloud ADC; the Linear MCP wants `LINEAR_API_KEY`. Don't enable what you won't use.
- **Sandboxing interaction**: MCP servers run as subprocesses. If you enable Claude Code's sandbox feature, the MCP's network needs (e.g. cloud.getdbt.com, api.linear.app) must be in the sandbox `allowedDomains` list.
