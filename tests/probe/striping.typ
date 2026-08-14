// Striping is a per-cell fill computed from the body row position, not a show
// rule, so its phase survives a page break. A fill that never reaches the cells
// renders as a table that simply is not striped, which reads as a theme choice
// rather than as a bug.
//
// The second table sets the same fill and leaves striping off, so the colour
// appearing at all would mean the option is being ignored.
//
// expect-svg: #ff0000
// reject-svg: #00ff00

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let data = (product: ("Bolt", "Nut", "Beam", "Plate"), units: (1250, 860, 430, 2100))

#display-table(
  data,
  columns-label(units: [Units]),
  table-options(row-striping: true, row-striping-fill: rgb("#ff0000")),
)

#display-table(
  data,
  columns-label(units: [Units]),
  table-options(row-striping: false, row-striping-fill: rgb("#00ff00")),
)
