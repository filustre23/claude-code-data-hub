"""Seed the KB with region-specific data quirks.

Captures regional differences in how Pokemon data is recorded across regions
(Kanto vs Johto vs Galar etc.).
"""

from __future__ import annotations

from lib.kb.ingest.base import IngestRow, IngestRunner

_QUIRKS: list[IngestRow] = [
    IngestRow(
        doc_type="region_quirk",
        project="kanto",
        title="Original 151 dex numbering",
        content=(
            "Kanto Pokedex numbers run 1-151 and predate the National Dex. Any "
            "join across regions must use national_dex_id, not regional_id. "
            "Several Kanto entries (Mr. Mime, Farfetch'd) have Galarian forms "
            "with the same national_dex_id but different type."
        ),
        tags=["kanto", "joins", "id-collision"],
    ),
    IngestRow(
        doc_type="region_quirk",
        project="johto",
        title="Day/Night encounter splits",
        content=(
            "Johto introduced time-of-day mechanics. Encounter rates in our "
            "encounter_log table are bucketed into morning/day/night windows. "
            "Filter on encounter_window when computing rarity — averaging across "
            "all three understates Hoothoot rates by ~3x."
        ),
        tags=["johto", "encounters", "time-of-day"],
    ),
    IngestRow(
        doc_type="region_quirk",
        project="galar",
        title="Dynamax inflates HP rows",
        content=(
            "Galar battle logs include Dynamax turns where HP can exceed the "
            "Pokemon's natural HP stat by up to 2x. Always filter "
            "is_dynamax_turn = false when computing damage-per-HP metrics."
        ),
        tags=["galar", "battle-log", "dynamax"],
    ),
]


def rows() -> list[IngestRow]:
    return list(_QUIRKS)


if __name__ == "__main__":
    runner = IngestRunner()
    diff = runner.dry_run(rows())
    print(diff.summary())
    if diff.has_writes():
        runner.apply(rows(), confirmed=True)
        print("applied.")
