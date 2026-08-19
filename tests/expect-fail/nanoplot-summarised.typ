// A column of nanoplots has nothing to aggregate. Left to itself it aggregated
// to nothing and rendered a blank cell, which reads as a total that happens to
// be missing rather than a question with no answer.
// expect: summary-rows: column trend holds nanoplots and cannot be summarised
// expect: Name the other columns: aggregating series of readings has no meaning.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (
    region: ("North", "North"),
    product: ("Bolt", "Nut"),
    trend: ((1.0, 1.2, 1.4), (2.0, 1.8, 1.6)),
  ),
  table-stub(rowname: "product", group: "region"),
  format-nanoplot("trend", plot: nanoplot-line),
  summary-rows(functions: (Total: aggregate-sum), columns: "trend"),
)
