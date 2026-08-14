// The same rules with a footer under them. The bottom rule belongs to the table
// rather than to whichever part happens to come last, so it is drawn here too,
// and the footer's own rule is drawn as well as it, not instead of it.
//
// expect-svg: stroke="#ff0000"
// expect-svg: stroke="#00ff00"
// expect-svg: stroke="#00ffff"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut"), units: (1250, 860)),
  table-header(title: [Regional sales]),
  columns-label(units: [Units]),
  format-integer("units"),
  table-footnote([Excludes returns.], locations: cells-column-labels(columns: "units")),
  table-source-note([Source: internal ledger.]),
  table-options(
    table-border-top: 1pt + rgb("#ff0000"),
    table-border-bottom: 1pt + rgb("#00ff00"),
    footer-border-top: 1pt + rgb("#00ffff"),
  ),
)
