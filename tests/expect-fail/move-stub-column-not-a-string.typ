// The same reach for a stub column: the stub takes the name it is given, and a
// move naming it is answered before the folded spec is validated.
// expect: columns-move: column 42 is in the stub
// expect: The stub sits on the leading edge; its columns are not reordered.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut"), units: (1, 2)),
  table-stub(rowname: 42),
  columns-move(42, before: "product"),
)
