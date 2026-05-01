Use when the user asks "what regions/datasets/tables exist?", "show me the schema", or wants to discover what's available in the catalog. Reads `catalog/<region>.yml`.

requires: [bigquery]

## Instructions

1. **Parse $ARGUMENTS** for an action and parameters. Supported actions:

   - **regions** (default if no args): List all available regions from `catalog/*.yml`
   - **datasets `<region>`**: List datasets for a region with roles and descriptions
   - **tables `<region>` [dataset]**: List tables (defaults to the region's prod dataset)
   - **schema `<region>` `<table>`**: Show live table schema from BigQuery (resolves dataset via `resolution_order`)
   - **freshness `<region>` [dataset]**: Show row counts and last-modified for all tables in a dataset (defaults to prod)
   - **find `<region>` `<search>`**: Search table and column names across all datasets

2. **Load the catalog** by reading `catalog/<region>.yml`. If the region arg doesn't match a catalog file, check if it's a dataset name and suggest the correct region.

3. **For catalog-only actions** (regions, datasets, tables, find):
   - Read the YAML file(s) and format output as markdown tables
   - No BigQuery access needed
   - For **tables**: show table name, description, grain, and row_count (if in catalog)
   - For **find**: search table names and descriptions across all datasets in the catalog

4. **For live actions** (schema, freshness):
   - Read the catalog to get the `gcp_project` and dataset names
   - **Schema**: `bq show --schema --format=prettyjson <project>:<dataset>.<table>`
   - **Freshness**: query the `__TABLES__` metadata view:
     ```sql
     SELECT table_id, row_count, ROUND(size_bytes/1e9, 2) AS size_gb,
       TIMESTAMP_MILLIS(last_modified_time) AS last_modified,
       TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), TIMESTAMP_MILLIS(last_modified_time), HOUR) AS hours_stale
     FROM `<project>.<dataset>.__TABLES__`
     ORDER BY last_modified_time DESC
     ```
   - **If CLI auth fails**: tell the user to run `gcloud auth application-default login`

5. **Table resolution**: When the user provides a table name without a dataset:
   - Read the region's `resolution_order` from the catalog
   - Check each dataset in order for a matching table
   - Report which dataset the table was found in

6. **Output** as formatted markdown tables with clear headers.

Use $ARGUMENTS for the action and parameters.
