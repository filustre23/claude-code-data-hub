Use when the user asks to document a model — generates the dbt schema YAML with column descriptions and starter tests.

## Instructions

1. **Parse $ARGUMENTS** for the model name to document.

2. **Detect transformation framework** in the project directory:
   - `dbt_project.yml` → dbt

3. **Read the model's SQL** to understand its logic.

4. **Read existing documentation** (if any):
   - dbt: schema YAML `description` fields, `docs` blocks

5. **Trace lineage** to understand upstream sources and downstream consumers.

6. **Generate documentation**:
   - **Model description**: 2-3 sentence summary of what this model does and why it exists
   - **Column descriptions**: for each column, explain what it represents, its data type, and any transformations applied
   - **Business context**: what business questions this model helps answer
   - **Usage examples**: sample queries analysts might run against this model
   - **Dependencies**: upstream models it reads from, downstream models that depend on it
   - **Update frequency**: how often this model refreshes (based on materialization and CI/CD config)

7. **Write the documentation**:
   - dbt: update schema YAML with descriptions, or generate a `docs` block
   - Optionally generate a standalone markdown doc if the user prefers

Use $ARGUMENTS for the model name.
