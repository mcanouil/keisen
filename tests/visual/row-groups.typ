// Groups declared by the document over data that carries no group column.
//
// Look for three things: the two rows no group claims leading the body with no
// label above them, the group labels sitting as subheaders over the rows they
// were given, and the subtotals closing each group. The data has no column
// saying which rows belong together, so this grouping exists only because the
// document says so.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    instrument: ("Cash", "Deposits", "Gilts", "Corporate bonds", "Equities", "Property"),
    holding: (12500, 8400, 32000, 15750, 47200, 21000),
  ),
  table-header(title: [Portfolio], subtitle: [Holdings at 31 March 2026]),
  table-stub(rowname: "instrument", label: [Instrument]),
  columns-label(holding: [Holding]),
  table-row-group([Fixed income], (2, 3)),
  table-row-group([Growth], row => row.instrument in ("Equities", "Property")),
  format-currency("holding", currency: "GBP", decimals: 0),
  summary-rows(functions: (Subtotal: aggregate-sum), columns: ("holding",)),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: ("holding",)),
  theme: theme-booktabs(),
)
