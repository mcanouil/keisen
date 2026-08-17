// A hidden column has no body cell to address, and it is not unknown either.
// expect: cells-body: column price is hidden
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  columns-hide("price"),
  table-style(style(fill: aqua), locations: cells-body(columns: "price")),
)
