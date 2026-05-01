Use when the user asks to add metrics, semantic layer entries, or MetricFlow definitions for an existing model. Scaffolds from the model's columns.

## Instructions

1. **Parse $ARGUMENTS** for the model name to build metrics from.

2. **Detect transformation framework** in the project directory:
   - `dbt_project.yml` → dbt

3. **Pull existing metric definitions from KB** — reuse before reinventing:
   ```bash
   uv run python -c "
   import json
   from lib.kb.search import search
   results = search('<model_name or metric domain>',
                    doc_types=['metric_definition'], limit=10)
   for r in results:
       print(f'[{r[\"similarity\"]:.3f}] {r[\"title\"]} | {(r[\"content\"] or \"\")[:300]}')
   "
   ```
   If a `metric_definition` row exists with the canonical formula and SQL for what the user is asking, reference it instead of writing a new one. If you're adding a new metric, propose ingesting it via `lib/kb/ingest/metric_definition.py` so the next analyst gets it for free.

4. **Read the model's SQL and schema** to understand available columns, types, and relationships.

4. **Identify metric candidates**:
   - Numeric columns → potential measures (count, sum, average, min, max)
   - Date/timestamp columns → potential time dimensions
   - Categorical columns → potential dimensions/group-by fields
   - ID columns → potential entity keys

5. **Detect the project's semantic layer** (if any):
   - dbt metrics (YAML in `metrics/` or alongside models)
   - LookML (`.lkml` files)
   - Other semantic layer tools

6. **Generate metric definitions** matching the project's format:
   - dbt metrics: YAML with `name`, `label`, `type`, `sql`, `timestamp`, `time_grains`, `dimensions`
   - LookML: `dimension` and `measure` blocks
   - If no semantic layer detected, generate dbt metrics YAML as default

7. **Output the definitions** and suggest where to place them in the project.

Use $ARGUMENTS for the model name.
