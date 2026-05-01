# Kanto Pokedex Pipeline — Project Memory

## What This Project Is

Daily ingest of Kanto-region encounter, trainer, and battle data into the `pokemon-warehouse` BigQuery project. Powers the analytics dashboards and feeds the `kanto_signal` dataset with derived metrics (gym leader winrate, type matchup imbalance).

## Stack

- **Transformation**: dbt
- **Warehouse**: BigQuery (`pokemon-warehouse`)
- **CI/CD**: GitHub Actions
- **Source**: PokeAPI nightly snapshots → GCS landing → BigQuery raw
- **Repo**: `~/Documents/personal/claude-code-data-hub` (this hub) + linked dbt project under `additionalDirectories`

## Key Models / Tables

- `kanto.pokemon` — one row per captured Pokemon, grain `pokemon_id`
- `kanto.species` — dex-level metadata (types, base stats), clustered by type
- `kanto.route_encounter` — partitioned by `encounter_date`, the spine for rarity calcs
- `kanto.battle_log` + `kanto.move_used` — fan-out 1:N from battle to moves; never query move-level without filtering battle_id
- `kanto_signal.gym_leader_winrate` — rebuilt nightly from battle_log

## Architecture Notes

- `int_pokemon_level_stats` recomputes IV/EV-adjusted stats; held_item is optional and was the source of the 2026-03-18 NULL-coalesce regression — keep `coalesce(held_item, 'none')` in the join.
- Resolution order is `kanto → kanto_staging → kanto_signal → pokedex_analytics`. Always go through `catalog/kanto.yml`, never hardcode the dataset.
- `pokeapi_staging` and `pokeapi` are shared sources — both Kanto and Johto read them. Don't add region-specific filters there.

## Known Issues

- Trainer ID 0 is a sentinel for NPCs; many of the older battle_log rows have it as the opponent. Filter `opponent_id > 0` for player-vs-player metrics.
- `route_encounter` for routes 22 and 23 has been double-counted on Sundays since the encounter_window backfill (2026-02). Fix is queued but the workaround is `where not (route_id in (22,23) and extract(dayofweek from encounter_date) = 1)`.

## Recent Changes

- 2026-04-12 — added `clustered_by [trainer_id, opponent_id]` to `battle_log`. Cut common gym-leader queries from 18s to 2s.
- 2026-04-02 — moved Mega Evolution flag from `pokemon` to `int_pokemon_level_stats` so it can vary by battle.

## Contacts

- Owner: me (personal project)
