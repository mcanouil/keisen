// A colour names the column it scales, so a name no column answers to draws
// nothing.
// expect: data-colour: unknown column unts
// expect: Known columns: product, units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  data-colour(rgb("#08306b"), columns: "unts"),
)
