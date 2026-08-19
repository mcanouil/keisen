// Two cells carrying the same caveat share a mark and one footer row, so the
// third directive here prints no row of its own. Counting the directives rather
// than the rows made row 2 addressable, and a style put on it landed nowhere.
// expect: cells-footnotes: note 2 is not in the table
// expect: Notes are numbered from zero, and this table has 2 of them.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (name: ("a", "b"), units: (1, 2)),
  table-footnote([Provisional.], locations: cells-body(rows: 0, columns: "units")),
  table-footnote([Measured at the till.], locations: cells-body(rows: 1, columns: "units")),
  table-footnote([Provisional.], locations: cells-body(rows: 1, columns: "name")),
  table-style(style(fill: aqua), locations: cells-footnotes(notes: 2)),
)
