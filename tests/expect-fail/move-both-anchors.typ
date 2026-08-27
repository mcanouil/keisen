// A column goes on one side of its anchor or the other. Given both, the second
// silently won.
// expect: columns-move: before and after cannot both be given
// expect: A column goes on one side of the anchor or the other.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3), price: (1.5, 2.5)),
  columns-move("price", before: "units", after: "product"),
)
