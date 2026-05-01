# Shiny Encounter Tracker — Project Memory

## What This Project Is

Personal log of shiny Pokemon encounters across regions, plus a stats backend that estimates per-method shiny rates with proper credible intervals (vs the headline 1/4096 / 1/8192 / 1/512 numbers). Built mostly to argue with friends about whether the SOS chain is "really" 1/273 after 31 calls.

## Stack

- **Transformation**: dbt (small footprint, mostly one mart)
- **Warehouse**: BigQuery (`pokemon-warehouse`)
- **Stats**: Python notebook with PyMC for the Bayesian posteriors

## Key Models / Tables

- `johto_signal.shiny_encounter_rate` — grain `(region, method, chain_length_bucket)`
- `marts.shiny_attempts` — one row per "attempt" (encounter or chain link), with `was_shiny` boolean
- `dim_shiny_method` — method-level metadata (base rate, charm-applicable, etc.)

## Architecture Notes

- "Attempt" is method-defined: for full-odds wild encounters, 1 attempt = 1 encounter. For Masuda Method, 1 attempt = 1 egg. For SOS, 1 attempt = 1 call after the first.
- Shiny Charm multiplier (3x) is applied at the rate level, not the data level — the raw `was_shiny` column doesn't know about the charm. Always join `dim_shiny_method` to get the effective rate.
- Soft-resets are excluded from `shiny_attempts` — they're recorded for completeness in `raw.soft_reset_log` but most analyses you want to drop them, since they double-count the same wild encounter.

## Known Issues

- The Pokeradar chain length cap of 40 means the long-tail rate (chain 41+) is undefined — we bucket as `40+`. Don't try to extrapolate.
- `was_shiny` was misencoded as a string `'true'/'false'` for one week of imports in 2026-Q1. The staging model coerces, but raw queries break.

## Recent Changes

- 2026-04-30 — finally caught a shiny Larvitar on a Masuda chain (n=247). Posterior median for Masuda+Charm in this sample now sits at 1/512, CI [1/420, 1/640].

## Contacts

- Owner: me
