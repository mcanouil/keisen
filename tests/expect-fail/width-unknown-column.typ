// A width names the column it sizes, so a name no column answers to sizes
// nothing and the table quietly kept its own measure.
// expect: columns-width: unknown column unts
// expect: Known columns: product, units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  columns-width((unts: 4cm)),
)
