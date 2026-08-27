// A column cannot be moved relative to itself: there is no position that
// answers it, and the arithmetic behind the move read one anyway.
// expect: columns-move: cannot move price relative to itself
// expect: Move relative to a column other than the ones being moved.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3), price: (1.5, 2.5)),
  columns-move("price", before: "price"),
)
