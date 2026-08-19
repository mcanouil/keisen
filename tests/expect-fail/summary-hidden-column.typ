// A hidden column exists, so saying it is unknown would send the reader hunting
// for a typo that is not there. It carries no summary either: the summary reads
// the columns the table renders.
// expect: summary-rows: column units is hidden
// expect: Summarise a visible column
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), region: ("N", "S"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  columns-hide("units"),
  summary-rows(functions: (Total: aggregate-sum), columns: "units"),
)
