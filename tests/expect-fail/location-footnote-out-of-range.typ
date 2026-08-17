// Footnote rows are numbered by where they land in the footer, so a position
// past the last one is a miscount. It used to be styled in silence.
// expect: cells-footnotes: note 2 is not in the table
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (1, 2)),
  table-footnote([Explains the table.]),
  table-footnote([Marks a cell.], locations: cells-body(rows: 0, columns: "units")),
  table-style(style(fill: aqua), locations: cells-footnotes(notes: 2)),
)
