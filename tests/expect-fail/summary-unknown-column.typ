// A summary naming a column the table does not carry rendered a bold Total row
// with every cell blank, and said nothing: a typo that reads as data which did
// not add up. Every other directive naming a column is already checked.
// expect: summary-rows: unknown column tpyo
// expect: Known columns: units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), region: ("N", "S"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  summary-rows(functions: (Total: aggregate-sum), columns: "tpyo"),
)
