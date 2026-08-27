// A column is named by a string. A name of any other type is written as its
// repr, so the error builder can report whatever it is handed rather than
// failing on a line of this package.
// expect: columns-hide: unknown column 42
// expect: Known columns: product, units.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut"), units: (1, 2)),
  columns-hide(42),
)
