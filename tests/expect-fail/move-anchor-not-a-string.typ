// The anchor names one column, so an array is not read as a list here the way a
// positional name is. It is reported as an unknown column, under the name it
// was written as.
// expect: columns-move: unknown column ("product",)
// expect: Known columns: product, units.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut"), units: (1, 2)),
  columns-move("units", before: ("product",)),
)
