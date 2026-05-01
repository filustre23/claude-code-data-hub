"""Seed the KB with canonical Pokemon move definitions.

Idempotent — re-running upserts the same rows.
"""

from __future__ import annotations

from lib.kb.ingest.base import IngestRow, IngestRunner

_MOVES: list[IngestRow] = [
    IngestRow(
        doc_type="move_definition",
        title="Thunderbolt",
        content=(
            "Thunderbolt — Electric-type, 90 power, 100 accuracy, 15 PP. "
            "10% chance to paralyze. Special attack. Standard 'good neutral' "
            "Electric option in most team builds."
        ),
        tags=["electric", "special", "status-chance"],
    ),
    IngestRow(
        doc_type="move_definition",
        title="Earthquake",
        content=(
            "Earthquake — Ground-type, 100 power, 100 accuracy, 10 PP. "
            "Hits all adjacent Pokemon in doubles. Physical attack. "
            "Useless against Flying-types and Levitate ability."
        ),
        tags=["ground", "physical", "spread"],
    ),
    IngestRow(
        doc_type="move_definition",
        title="Stealth Rock",
        content=(
            "Stealth Rock — Rock-type entry hazard. On switch-in, deals damage "
            "based on the Pokemon's Rock-type matchup. 4x damage to Charizard, "
            "Volcarona, etc. Single-handedly defines competitive team building."
        ),
        tags=["rock", "hazard", "competitive"],
    ),
]


def rows() -> list[IngestRow]:
    return list(_MOVES)


if __name__ == "__main__":
    runner = IngestRunner()
    diff = runner.dry_run(rows())
    print(diff.summary())
    if diff.has_writes():
        runner.apply(rows(), confirmed=True)
        print("applied.")
