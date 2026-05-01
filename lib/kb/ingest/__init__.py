"""KB ingest framework.

Each `<doc_type>.py` module in this package defines an idempotent ingest
script for one doc_type. The framework lives in `base.py`:

    from lib.kb.ingest.base import IngestRow, IngestRunner

    rows = [IngestRow(doc_type="pokedex_entry", title="Pikachu", content="...")]
    runner = IngestRunner()
    diff = runner.dry_run(rows)         # always run dry-run first
    print(diff.summary())
    runner.apply(rows, confirmed=True)  # write only after curator approval
"""

from lib.kb.ingest.base import IngestDiff, IngestRow, IngestRunner

__all__ = ["IngestDiff", "IngestRow", "IngestRunner"]
