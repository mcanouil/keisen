// A move is relative to a column, so with neither before nor after there is
// nothing to be relative to.
// expect: columns-move: no anchor given
// expect: Pass before: or after: naming the column to move relative to.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3), price: (1.5, 2.5)),
  columns-move("price"),
)
