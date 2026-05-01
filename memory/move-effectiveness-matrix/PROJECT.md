# Move Effectiveness Matrix — Project Memory

## What This Project Is

Computes empirical type-matchup effectiveness from the `move_used` table — i.e., what's the actual mean damage multiplier when a Fire move hits a Steel/Flying type, across hundreds of thousands of recorded battles. Companion to the canonical 18×18 type chart.

## Stack

- **Transformation**: dbt + a Python notebook for the heatmap visualization
- **Warehouse**: BigQuery (`pokemon-warehouse`)

## Key Models / Tables

- `kanto.move_used` + `johto.move_used` (cross-region UNION ALL in `int_move_used_all`)
- `dim_move` — move id → type, category (physical/special/status), base power
- `dim_species_type` — species id → primary/secondary type
- `marts.move_effectiveness` — grain `(attacker_type, defender_type_1, defender_type_2)`, with mean/median/p95 of the damage multiplier

## Architecture Notes

- STAB (Same-Type Attack Bonus) confounds raw damage multipliers. The mart strips STAB by dividing by 1.5 when `attacker_type` matches the move user's type — see the `stab_adjusted_multiplier` column.
- Critical hits should be excluded when measuring "type effectiveness," not "real-world output." We keep both columns: `mean_multiplier_all` and `mean_multiplier_no_crits`.
- Status moves (`category = 'status'`) have no damage and are always excluded.

## Known Issues

- Inverse Battle and Magic Room data is mixed into the raw move_used unless you filter `battle_format = 'standard'`. Forgetting this turned the Ghost-vs-Normal cell green in an early dashboard.
- For dual-type defenders, the mart represents the joint cell; for single-type, defender_type_2 is `'none'` — handle the NULL/sentinel split carefully when building the heatmap.

## Recent Changes

- 2026-04-18 — added confidence intervals via bootstrap (1000 resamples). Cells with n<100 are now rendered as gray.

## Contacts

- Owner: me
