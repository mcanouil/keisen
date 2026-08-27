// A summary row closes a group, so a table with no groups has nothing for one
// to close. The whole body is grand-summary-rows instead.
// expect: summary-rows: there are no groups to summarise
// expect: Give table-stub a group column, declare groups with table-row-group, or use grand-summary-rows for the whole body.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  summary-rows(functions: (Total: aggregate-sum), columns: "units"),
)
