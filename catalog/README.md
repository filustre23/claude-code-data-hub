# Region Catalog

Structural metadata for each region (Kanto, Johto, …). Skills and agents read these to resolve warehouse connections.

**Table descriptions, column details, and row counts live in the Knowledge Base** (ChromaDB). Catalog YAMLs contain only structural metadata: grain, partitioning, clustering, dataset roles, and resolution order.

## Schema

```yaml
tenant: <name>
gcp_project: <project_id>
default_dataset: <dataset>

datasets:
  <dataset_name>:
    role: prod | staging | source | signal | analytics
    shared: true                  # optional — cross-region dataset
    tables:
      <table_name>:
        grain: <what one row represents>
        partitioned_by: <partition column>
        clustered_by: [<col1>, <col2>]

resolution_order:
  - <dataset_1>                   # checked first (usually prod)
  - <dataset_2>
```

## Adding a new region

1. Copy an existing catalog file (e.g., `kanto.yml`)
2. Update tenant name, GCP project, and datasets
3. List tables with grain and physical layout (partitioning, clustering)
4. Set `resolution_order` with prod first
5. Add table descriptions to the KB via `/connection-kb`

## How skills use the catalog

Skills follow the resolution chain defined in CLAUDE.md (Catalog → KB → dbt → Ask user). The catalog is the first step: skills read the region YAML for structural metadata, then enrich with KB context.
