// The regression this harness exists for: a table with no source notes drew no
// closing rule under any theme, and the suite stayed green because every visual
// test happened to carry a note. The footer used to draw that rule, so a table
// with no footer lost it.
//
// Each rule takes a colour of its own, so an assertion names one rule rather
// than "some stroke somewhere".
//
// expect-svg: stroke="#ff0000"
// expect-svg: stroke="#00ff00"
// expect-svg: stroke="#0000ff"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut"), units: (1250, 860)),
  table-header(title: [Regional sales]),
  columns-label(units: [Units]),
  format-integer("units"),
  table-options(
    table-border-top: 1pt + rgb("#ff0000"),
    table-border-bottom: 1pt + rgb("#00ff00"),
    column-labels-border-bottom: 1pt + rgb("#0000ff"),
  ),
)
