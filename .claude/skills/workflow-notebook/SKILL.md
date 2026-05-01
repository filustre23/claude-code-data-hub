Use when the user asks to create a new Jupyter notebook for an analysis topic — scaffolds warehouse connection cells and starter queries.

## Instructions

1. **Parse $ARGUMENTS** for the analysis topic or question.

2. **Detect the warehouse** from project config:
   - dbt: read `profiles.yml` for connection type and credentials setup

3. **Read relevant model/source schemas** to understand available tables and columns for the topic.

4. **Create a Jupyter notebook** (`.ipynb`) with the following cells:

   **Cell 1 - Setup**: Import standard libraries:
   - `pandas`, `numpy` for data manipulation
   - Warehouse connector (`google.cloud.bigquery`, `snowflake.connector`, `sqlalchemy`, etc.)
   - `matplotlib`, `seaborn` for visualization (if relevant)

   **Cell 2 - Connection**: Warehouse connection boilerplate using the project's config:
   - BigQuery: `bigquery.Client(project=...)`
   - Snowflake: `snowflake.connector.connect(...)` with env var placeholders
   - Other: appropriate connector with config from profiles

   **Cell 3 - Data Loading**: SQL queries to load relevant tables as DataFrames, based on the topic and available models/sources.

   **Cell 4+ - Analysis**: Starter analysis cells based on the topic:
   - Summary statistics
   - Initial visualizations
   - Markdown cells with analysis prompts/questions to explore

5. **Save the notebook** to a sensible location (project root or `notebooks/` if it exists).

6. **Report** what was created and suggest next steps.

Use $ARGUMENTS for the analysis topic.
