// A summary row answers to the label that names it, so a label no summary
// carries is a typo like any other name.
// expect: cells-grand-summary: unknown summary row "Nope"
// expect: Known summary rows: Total.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2)),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units",)),
  table-style(style(fill: aqua), locations: cells-grand-summary(rows: "Nope")),
)
