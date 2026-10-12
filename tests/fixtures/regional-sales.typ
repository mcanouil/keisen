// The regional sales table, shared so that tests/visual/grouped.typ renders it
// and tests/visual/anatomy.typ labels the same call. It sits outside
// tests/visual/ because it is a module, not a document to render.

#import "../../lib.typ": *

#let regional-sales = display-table(
  (
    product: ("Bolt", "Nut", "Beam", "Plate"),
    region: ("North", "North", "South", "South"),
    units: (1250, 860, 430, 2100),
    revenue: (18750.5, 12900.25, 21500, 31500.75),
  ),
  table-header(title: [Regional sales], subtitle: [Financial year 2025 to 2026]),
  table-stub(rowname: "product", group: "region", label: [Product]),
  columns-label(units: [Units], revenue: [Revenue]),
  table-spanner([Performance], ("units", "revenue")),
  format-integer("units"),
  format-number("revenue", decimals: 2),
  summary-rows(functions: (Subtotal: aggregate-sum), columns: ("units", "revenue")),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units", "revenue")),
  table-source-note([Source: internal ledger.]),
  table-options(row-striping: true),
)
