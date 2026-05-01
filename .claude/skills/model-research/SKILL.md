Use when the user asks to investigate, understand, "tell me everything about" an existing dbt model, or just trace its lineage before working on it — KB context, upstream/downstream lineage, tests, git history, CI status. Lineage-only requests skip sub-agents 1 and 3.

## Instructions

1. **Parse $ARGUMENTS** for the model name to research.

2. **Detect transformation framework** in the project directory:
   - `dbt_project.yml` → dbt

3. **Find the model file** by searching the models directory for files matching the name.

4. **Pull KB context** for the model:
   ```bash
   uv run python -c "
   import json
   from lib.kb.search import search
   results = search('<model_name>', limit=10)
   for r in results:
       print(f'[{r[\"similarity\"]:.3f}] {r[\"doc_type\"]:18} | {r[\"content\"][:200]}')
   "
   ```
   Use KB results to pre-load:
   - **table_summary** → column names, types, row counts, relationships
   - **glossary_term** → business definitions for key concepts in this model
   - **query_example** → how this model is typically queried downstream
   - **routing_rule** → region-specific logic that may affect this model

   Feed this context into the sub-agents below. If the KB is unreachable, continue without it.

5. **Launch parallel sub-agents** to research the following areas simultaneously:

### Sub-agent 1: Logic & Schema
- Read the model SQL and understand the transformation logic
- Read the schema definition (dbt: `schema.yml` / `*.yml`)
- List all columns with types, descriptions, and any transformations applied
- Identify materialization strategy (table, view, incremental, ephemeral)
- Note any variables, filters, or conditional logic (e.g. region filtering, incremental predicates)
- List all tests/assertions defined on this model

### Sub-agent 2: Lineage & Dependencies
- Trace **upstream lineage** recursively:
  - dbt: `{{ ref('...') }}` and `{{ source('...') }}`
  - Follow references until raw sources are reached
- Trace **downstream lineage** by searching all model files for references to this model
- Build the full DAG with layer labels (staging, intermediate, core, production)
- For each connected model: name, file path, layer, one-line description

### Sub-agent 3: History & Status
- Run `git log` on the model file to get recent change history (last 10 commits)
- Identify who last modified it and when
- Check for open PRs or branches that touch this model
- If CI/CD is available (`.github/workflows/`), check if recent pipeline runs involving this model passed or failed
- Check freshness: query table metadata if warehouse access is available, or read freshness config from source YAML

6. **Synthesize the research** into a structured briefing:

   ## Model Research: `<model_name>`

   ### Summary
   - 2-3 sentence plain-English description of what this model does and why it exists

   ### Layer & Materialization
   - Layer (staging / intermediate / core / production)
   - Materialization (table / view / incremental / ephemeral)
   - Warehouse target (if detectable)

   ### Logic
   - Key transformations and business rules
   - Variables or dynamic filtering
   - Notable complexity or gotchas

   ### Schema
   - Column table: name, type, description
   - Tests/assertions defined

   ### Lineage
   ```
   source_table
     → stg_model
       → THIS_MODEL  ← YOU ARE HERE
         → downstream_model
   ```

   ### Freshness & Status
   - Last updated timestamp (if available)
   - Freshness status: fresh / warning / stale
   - Latest CI/CD run status (pass / fail / unknown)

   ### Recent Changes
   - Last 5 commits touching this file (date, author, message)
   - Any open PRs modifying this model

   ### Risk Assessment
   - Number of downstream dependents (blast radius)
   - Failing tests or assertions
   - Staleness warnings
   - Any recent churn (frequent changes may indicate instability)

Use $ARGUMENTS for the model name.
