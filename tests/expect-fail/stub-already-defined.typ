// One table-stub per table. A second one used to replace the first without a
// word, so the columns of the first quietly returned to the body.
// expect: table-stub: the stub is already defined
// expect: One table-stub per table; put every stub column in that one call.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (region: ("N", "S"), product: ("Bolt", "Nut"), units: (5, 3)),
  table-stub(rowname: "product"),
  table-stub(group: "region"),
)
