// Ordering runs before the folded spec is validated, so a hidden column that is
// not a string reaches the move check first. It is reported as hidden, under
// the name it was written as.
// expect: columns-move: column 42 is hidden
// expect: Move a visible column, or drop the columns-hide.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut"), units: (1, 2)),
  columns-hide(42),
  columns-move(42, before: "product"),
)
