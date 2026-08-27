// A hidden column that does not exist is a typo. Left unchecked, it whitelisted
// the same typo for every other directive, since a hidden name is a known one.
// expect: columns-hide: unknown column unts
// expect: Known columns: product, units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  columns-hide("unts"),
)
