// A summary row answers to its label or its position, so a selector that is
// neither addresses no summary row.
// expect: cells-summary: rows selector is not a summary row
// expect: got 2.5.
// expect: Give auto, a label, a position, an array of either, or a predicate over the label.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (region: ("N", "N"), product: ("Bolt", "Nut"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  summary-rows(functions: (Total: aggregate-sum), columns: "units"),
  table-style(style(fill: aqua), locations: cells-summary(rows: 2.5)),
)
