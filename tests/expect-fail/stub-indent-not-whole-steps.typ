// The indent column counts steps, so a level is a whole number of them. A
// fraction reached the renderer and multiplied the step by itself.
// expect: table-stub: indent level in row 1 is not a whole number of steps
// expect: got 1.5.
// expect: An indent column holds non-negative integers.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), depth: (0, 1.5), units: (5, 3)),
  table-stub(rowname: "product", indent: "depth"),
)
