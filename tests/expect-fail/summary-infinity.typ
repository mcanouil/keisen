// An infinity is a value the table shows, so a summary over the column it sits
// in cannot quietly leave it out: every aggregation works in `decimal`, which
// holds no infinity, and a total that skipped one would read as the total of
// the column it is printed under.
// expect: grand-summary-rows: column ratio holds an infinite value in row 1 and cannot be summarised
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (name: ("a", "b"), ratio: (1.5, float.inf)),
  table-stub(rowname: "name"),
  format-number("ratio", infinity: [∞]),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: ("ratio",)),
)
