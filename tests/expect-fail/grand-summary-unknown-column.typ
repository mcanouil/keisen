// The grand summary reports under the directive the caller wrote. Both summary
// directives were reported as `summary-rows`, which named a call that is not in
// the document.
// expect: grand-summary-rows: unknown column tpyo
// expect: Known columns: units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), region: ("N", "S"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: "tpyo"),
)
