"""Seed the KB with a small set of Pokedex entries.

Idempotent — re-running upserts the same rows.
"""

from __future__ import annotations

from lib.kb.ingest.base import IngestRow, IngestRunner

_ENTRIES: list[IngestRow] = [
    IngestRow(
        doc_type="pokedex_entry",
        project="kanto",
        title="Pikachu",
        content=(
            "Pikachu (#025) is an Electric-type Mouse Pokemon. Stores electricity "
            "in its cheek pouches and discharges it through its tail. Evolves into "
            "Raichu when exposed to a Thunder Stone."
        ),
        tags=["electric", "kanto", "starter-adjacent"],
    ),
    IngestRow(
        doc_type="pokedex_entry",
        project="kanto",
        title="Charizard",
        content=(
            "Charizard (#006) is a Fire/Flying-type Flame Pokemon. Final evolution of "
            "Charmander. Mega Charizard X is Fire/Dragon. Weak to Rock (4x), Electric, "
            "and Water."
        ),
        tags=["fire", "flying", "kanto", "final-evolution"],
    ),
    IngestRow(
        doc_type="pokedex_entry",
        project="johto",
        title="Typhlosion",
        content=(
            "Typhlosion (#157) is a Fire-type Volcano Pokemon. Final evolution of "
            "Cyndaquil. Hidden ability Flash Fire absorbs Fire moves to power up its own."
        ),
        tags=["fire", "johto", "starter", "final-evolution"],
    ),
]


def rows() -> list[IngestRow]:
    return list(_ENTRIES)


if __name__ == "__main__":
    runner = IngestRunner()
    diff = runner.dry_run(rows())
    print(diff.summary())
    if diff.has_writes():
        runner.apply(rows(), confirmed=True)
        print("applied.")
