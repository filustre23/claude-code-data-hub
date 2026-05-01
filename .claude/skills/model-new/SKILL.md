Use when the user asks to create or scaffold a new dbt model in any layer (staging, intermediate, core, mart). Pulls KB context for conventions and joins.

## Instructions

1. **Parse $ARGUMENTS** for the target layer (staging, intermediate, core, production) and model name.

2. **Detect transformation framework** in the project directory:
   - `dbt_project.yml` → dbt (create `.sql` + schema YAML)

3. **Pull KB context** for the new model's domain:
   ```bash
   uv run python -c "
   import json
   from lib.kb.search import search
   doc_types = ['table_summary', 'glossary_term', 'join_recipe',
                'metric_definition', 'cross_skill_convention']
   results = search('<model_name or domain>', doc_types=doc_types, limit=12)
   for r in results:
       print(f'[{r[\"similarity\"]:.3f}] {r[\"doc_type\"]:24} | {(r[\"content\"] or \"\")[:200]}')
   "
   ```
   Use KB results to understand:
   - Related tables and schemas — from `table_summary`
   - Business definitions for the domain — from `glossary_term`
   - **Reuse over reinvention**: existing join patterns (`join_recipe`) and metric definitions (`metric_definition`). If a recipe exists for the join you're about to write, use it.
   - Team conventions — from `cross_skill_convention` (SQL style, naming, partition strategy)

   If the KB is unreachable, continue with catalog YAML and existing model inspection.

4. **Read 2-3 existing models in the target layer** to extract conventions:
   - Config block pattern (materialization, schema, partitioning, clustering)
   - Naming conventions (prefix like `stg_`, `int_`, `prod_`)
   - Common patterns (source references, variable usage, deleted record filtering)
   - Test patterns (unique, not_null, recency, custom)

5. **Create the model file** in the correct directory:
   - dbt: `models/<layer>/<model_name>.sql` with config block matching conventions

6. **Create or update the schema file**:
   - dbt: add entry to existing `schema.yml` or create one with standard tests

7. **Compile to verify**:
   - dbt: `dbt compile --select <model_name>`

8. **Report** what was created and any manual steps remaining (e.g. "add source columns", "define upstream ref").

Use $ARGUMENTS for layer and model name.
