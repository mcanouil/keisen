// A summary naming a group the table does not carry produced no row at all and
// said nothing. The location DSL refuses the same name, so a style could address
// a summary row that the directive never made.
// expect: summary-rows: unknown group "Nowhere"
// expect: Known groups: "N", "S".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), region: ("N", "S"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  summary-rows(functions: (Total: aggregate-sum), groups: "Nowhere"),
)
