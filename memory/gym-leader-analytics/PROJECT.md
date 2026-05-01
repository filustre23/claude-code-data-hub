# Gym Leader Analytics — Project Memory

## What This Project Is

Cross-region analytics on gym leaders: winrate against challengers, signature Pokemon usage, type bias, badge issuance velocity. Surfaces "is the Cinnabar gym too easy?" type questions for game-balance discussions.

## Stack

- **Transformation**: dbt
- **Warehouse**: BigQuery (`pokemon-warehouse`)
- **Notebooks**: Jupyter under `~/Documents/personal/notebooks/gym-leader-analytics/`

## Key Models / Tables

- `kanto_signal.gym_leader_winrate` — daily-rebuilt, one row per gym leader.
- `johto_signal.gym_leader_winrate` — same shape.
- `dim_gym_leader` — slowly-changing dimension (Type 2). When Sabrina swapped from Psychic-only to mixed in 2026-02, that's a new row with valid_from set.

## Architecture Notes

- Always join `dim_gym_leader` with `valid_from <= battle_date < valid_to` — using just `current_flag = true` would attribute pre-rebalance battles to the post-rebalance lineup.
- Challenger skill bias: ranked challengers vs casual challengers are very different distributions. Always segment.
- Win is `battle_log.outcome = 'leader_win'`; "draw" outcomes (rare, mostly Struggle ties) are excluded from the rate denominator — note in dashboard.

## Known Issues

- Pre-2025 battle_log rows don't have `is_ranked`; default-imputing to `false` underestimates ranked winrate for the early period. Flag in any time-series view.
- Brock's badge issuance count was inflated by a duplicate-emit bug in 2026-Q1. The dedupe lives in `int_badge_issuance` — don't go straight to raw.

## Recent Changes

- 2026-04-25 — added Mega-Evolution-eligible flag to gym leader profile so we can split winrate by Mega-allowed vs not.

## Contacts

- Owner: me
