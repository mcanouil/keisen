// Source notes are numbered from zero, so a position past the last one is a
// miscount rather than a note that happens to be absent.
// expect: cells-source-notes: note 1 is not in the table
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2)),
  table-source-note([Source: ledger.]),
  table-style(style(fill: aqua), locations: cells-source-notes(notes: 1)),
)
