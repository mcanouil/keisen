// A combined column holds content built from columns that are no longer shown,
// so it has no total. Naming it in a summary says the reader expected an
// aggregate that cannot exist.
// expect: grand-summary-rows: column effect is combined from other columns and cannot be summarised

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (gene: ("BRCA1", "TP53"), estimate: (1.2, 3.4), error: (0.1, 0.2)),
  table-stub(rowname: "gene"),
  columns-combine("effect", ("estimate", "error"), (value, spread) => [#value (#spread)]),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: "effect"),
)
