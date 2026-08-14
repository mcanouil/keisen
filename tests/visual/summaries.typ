// Styling and marking the summary rows, which no location could address until
// cells-summary and cells-grand-summary existed: the renderer looked their
// styles up and nothing ever produced the addresses, so every such style
// silently did nothing.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    region: ("North", "North", "South", "South"),
    product: ("Bolt", "Nut", "Beam", "Plate"),
    units: (1250, 860, 430, 2100),
    revenue: (18750.5, 12900.25, 21500, 31500.75),
  ),
  table-header(title: [Regional sales], subtitle: [Financial year 2025 to 2026]),
  table-stub(rowname: "product", group: "region", label: [Product]),
  columns-label(units: [Units], revenue: [Revenue]),
  format-integer("units"),
  format-number("revenue", decimals: 2),
  summary-rows(functions: (Subtotal: aggregate-sum), columns: ("units", "revenue")),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units", "revenue")),
  // The whole subtotal row, its label included, and then the grand total alone.
  table-style(style(fill: luma(235)), locations: cells-summary()),
  table-style(
    style(text: (fill: rgb("#08519c"))),
    locations: cells-grand-summary(columns: "revenue"),
  ),
  // On the row once, through its label cell, rather than on every cell of it.
  table-footnote(
    [Subtotals exclude intra-group sales.],
    locations: cells-summary(groups: "North", columns: none),
  ),
  table-footnote([Audited.], locations: cells-grand-summary(columns: "revenue")),
  table-source-note([Source: internal ledger.]),
  theme: theme-booktabs(),
)
