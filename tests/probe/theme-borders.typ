// The four rules that the theme grew: between the columns, between the rows,
// and around the body. Declaring an option only proves the renderer reads the
// key; it does not prove a rule is drawn, which is what this file watches.
//
// Each rule takes a colour of its own, so an assertion names one rule rather
// than "some stroke somewhere".
//
// The body rules share their edges with the parts above and below: the line
// under the column labels is the line over the body, and the line over the
// footer is the line under it. A part draws its own edge as a cell rule, which
// wins over the table's, so the preset's two rules are turned off here to leave
// those edges to the body. Without that this file would prove nothing, and the
// two colours below would never reach the render.
//
// expect-svg: stroke="#ff0000"
// expect-svg: stroke="#00ff00"
// expect-svg: stroke="#0000ff"
// expect-svg: stroke="#ff00ff"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut", "Beam"), units: (1250, 860, 40)),
  columns-label(units: [Units]),
  format-integer("units"),
  table-source-note([Source: ledger.]),
  table-options(
    column-border: 1pt + rgb("#ff0000"),
    row-border: 1pt + rgb("#00ff00"),
    body-border-top: 1pt + rgb("#0000ff"),
    body-border-bottom: 1pt + rgb("#ff00ff"),
    column-labels-border-bottom: none,
    footer-border-top: none,
  ),
)

// With no footer the body closes the table, so its own rule is the last edge
// rather than the top of the row below. That is a different branch, and the
// colour is its own so this table cannot borrow the one above. The table's own
// closing rule claims that edge first, so the preset's is turned off as well.
//
// expect-svg: stroke="#00ffff"

#display-table(
  (product: ("Bolt", "Nut"), units: (1250, 860)),
  format-integer("units"),
  table-options(
    body-border-bottom: 1pt + rgb("#00ffff"),
    column-labels-border-bottom: none,
    table-border-bottom: none,
  ),
)
