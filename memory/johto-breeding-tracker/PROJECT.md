# Johto Breeding Tracker — Project Memory

## What This Project Is

Tracks egg-group lineage, IV inheritance, and shiny rates from the Johto Day Care. Built to answer "what's the cheapest path to a 5IV Larvitar" type questions and to spot data quality issues in the breeding logs.

## Stack

- **Transformation**: dbt
- **Warehouse**: BigQuery (`pokemon-warehouse`)
- **CI/CD**: GitHub Actions
- **Source**: in-game day care log → API export → GCS → BigQuery raw

## Key Models / Tables

- `johto.day_care_session` — grain `session_id`, partitioned by `start_date`. One pair-up = one row.
- `johto.egg_hatch` — grain `egg_id`, partitioned by `hatch_date`. Joined to session via `session_id`.
- `johto_signal.breeding_iv_distribution` — cached daily for the dashboard.
- `int_breeding_lineage` — recursive CTE walking parent → offspring up to 5 generations.

## Architecture Notes

- IV inheritance is non-deterministic in the source — the same parent pair can produce different IV spreads. Don't try to dedupe on `(parent_a_id, parent_b_id)`; the grain is genuinely the egg.
- `shiny_method` column is one of `random`, `masuda`, `chained`, `radar`. The Masuda method only kicks in when parents have different `original_trainer_country_code` values — there's a `region_quirk` doc in the KB about this.
- Egg cycles are clock ticks, not seconds. Convert with `cycles * 256` to get steps; the conversion lives in `dim_egg_cycle_constants`.

## Known Issues

- ~3% of `egg_hatch` rows have a NULL `parent_b_id` for "ditto + ditto" pairings (data bug upstream). These are dropped from breeding_iv_distribution silently; flag this in the dashboard footnote.
- Day Care fees were re-tiered in the 2026-03 patch. Pre-patch and post-patch fees aren't reconciled in `dim_day_care_fee` yet.

## Recent Changes

- 2026-04-22 — added `johto.egg_hatch.is_perfect_iv` (boolean, all six IVs == 31) for the leaderboard.
- 2026-04-09 — backfilled `original_trainer_country_code` from raw NDS save dumps.

## Contacts

- Owner: me
