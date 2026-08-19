// A summary row is an aggregate of a column, so there is no row behind it for a
// cell formatter to read. Named as a summary's own format it would reach the
// closure with the aggregate and die as a Typst type error, naming neither the
// directive nor the reason.
// expect: grand-summary-rows: format cannot be a cell formatter
// expect: A summary row has no row to read; use format() or one of the format-* directives.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2)),
  grand-summary-rows(
    functions: (Total: aggregate-sum),
    columns: ("units",),
    format: format-cell("units", row => [#(row.units)]),
  ),
)
