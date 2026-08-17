// A spanner is addressed by its label, so a label no spanner carries is the
// same typo as an unknown column.
// expect: cells-column-spanners: unknown spanner
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-spanner([Figures], ("units", "price")),
  table-style(style(fill: aqua), locations: cells-column-spanners(spanners: [Missing])),
)
