// The table from grouped.typ, with each part named in the margin. The landing
// page of the documentation shows it, so a reader learns the parts before the
// functions that build them.
//
// Each label finds its row from the table itself: a show rule leaves a marker in
// every cell, and the label sits at the height of the first cell in its row. The
// labels therefore follow the table when its spacing changes.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let ink = rgb("#C8442F")

// Grid rows of the table below, counted from zero, each with its label.
#let parts = (
  (row: 0, name: [header]),
  (row: 2, name: [spanner]),
  (row: 3, name: [column labels]),
  (row: 4, name: [row group]),
  (row: 5, name: [stub and body]),
  (row: 7, name: [summary row]),
  (row: 12, name: [grand summary]),
  (row: 13, name: [source note]),
)

#show table.cell: it => [#metadata((x: it.x, y: it.y))<anatomy-cell>] + it

#let sales = display-table(
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

#let label-width = 2.6cm
#let leader = 12pt
#let gap = 4pt

#grid(
  columns: (auto, gap + leader + gap + label-width),
  sales,
  [
    #metadata(none)<anatomy-origin>
    #context {
      let origin = query(<anatomy-origin>).map(m => m.location().position().y)
      let markers = query(<anatomy-cell>)
      // The first layout pass has no markers yet, so the labels wait for the next.
      if origin.len() == 0 or markers.len() == 0 { return }
      for part in parts {
        let cells = markers.filter(m => m.value.y == part.row)
        assert(
          cells.len() > 0,
          message: "anatomy: no cell in grid row " + str(part.row) + "; got " + repr(part.name) + ". Update the row numbers in `parts` to match the table.",
        )
        let dy = calc.min(..cells.map(m => m.location().position().y)) - origin.first()
        place(top + left, dx: gap, dy: dy + 0.9em, line(length: leader, stroke: 0.5pt + ink))
        place(top + left, dx: gap + leader + gap, dy: dy + 0.45em, text(fill: ink, style: "italic", part.name))
      }
    }
  ],
)
