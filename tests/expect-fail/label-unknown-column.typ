// A label names the column it heads, so a name no column answers to labels
// nothing.
// expect: columns-label: unknown column unts
// expect: Known columns: product, units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  columns-label(unts: [Units]),
)
