# External Services

Skills that interact with external services use local CLIs and APIs with direct authentication. Each skill declares its dependencies via `requires: [service]`. The leader agent checks auth before execution.

| Service | Auth | Setup |
|---------|------|-------|
| BigQuery | `gcloud auth` (ADC) | `gcloud auth application-default login` |
| GitHub | `gh` CLI | `gh auth login` |
| Linear | `LINEAR_API_KEY` env var | Token from https://linear.app/settings/api |
| Snowflake | env vars or `profiles.yml` | Set `SNOWFLAKE_*` env vars or configure `profiles.yml` |
| KB | none — local ChromaDB | Seed with `uv run python -m lib.kb.ingest.<doc_type>` |

Run `/setup-init` to set up authentication for all services interactively.

## MCP servers

Some services are also accessible via MCP servers (configured in `.mcp.json`):

- dbt MCP server (official) — replaces shell-out for live job/run queries
- Google MCP Data Toolbox — unified BigQuery + Postgres
- Linear MCP — replaces GraphQL curl

When an MCP is available, prefer it for "query / fetch / current state" operations. Use the corresponding `connection-*` skill for "how we do things here" methodology.
