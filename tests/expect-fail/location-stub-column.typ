// A column that exists but sits in the stub is not an unknown column, and
// saying so would send the reader hunting for a typo that is not there.
// expect: cells-body: column product is in the stub
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (1, 2)),
  table-stub(rowname: "product"),
  table-style(style(fill: aqua), locations: cells-body(columns: "product")),
)
