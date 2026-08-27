// Every other format directive carries a formatter, and the paths that
// aggregate a column reach for it. A nanoplot has none: naming one as the
// summary's own format hands it a total, which is a number where a series was
// wanted.
// expect: format-nanoplot: a column of nanoplots cannot be summarised
// expect: got decimal("8").
// expect: Name the other columns in summary-rows: aggregating series of readings has no meaning.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  grand-summary-rows(
    functions: (Total: aggregate-sum),
    columns: "units",
    format: format-nanoplot("units", plot: nanoplot-line),
  ),
)
