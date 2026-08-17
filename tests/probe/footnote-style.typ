// A footnote row is styled through cells-footnotes, as a source note is
// through cells-source-notes. The renderer emitted footnote rows with no style
// lookup at all, so every style aimed at one was dropped in silence.
//
// The first table fills the second footnote row, which is the unmarked note:
// the footer prints the marked notes first, whichever order they were written
// in. The second table styles the first row instead, so the two fills landing
// on the same row would show as one colour missing.
//
// A row past the last one used to be styled in silence; it is now reported, and
// tests/expect-fail/location-footnote-out-of-range.typ holds it.
//
// expect-svg: #ff0000
// expect-svg: #0000ff

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let data = (product: ("Bolt", "Nut"), units: (1250, 860))

#display-table(
  data,
  columns-label(units: [Units]),
  table-footnote([Explains the table.]),
  table-footnote([Marks a cell.], locations: cells-body(rows: 0, columns: "units")),
  table-style(style(fill: rgb("#ff0000")), locations: cells-footnotes(notes: 1)),
)

#display-table(
  data,
  columns-label(units: [Units]),
  table-footnote([Explains the table.]),
  table-footnote([Marks a cell.], locations: cells-body(rows: 0, columns: "units")),
  table-style(style(fill: rgb("#0000ff")), locations: cells-footnotes(notes: 0)),
)
