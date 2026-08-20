// A spanner naming a column the table does not have failed where the column
// order was read, as a raw Typst error that named neither the spanner nor the
// columns the table does have.
// expect: table-spanner: unknown column cost
// expect: Known columns: units, price.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-spanner([Figures], ("units", "cost")),
)
