// The rules a theme draws, on tables whose parts differ. The suite used to be
// green while the closing rule was missing, because every table here carried a
// source note and the footer was drawing it.

#import "../../lib.typ": *

#set page(width: 15cm, height: auto, margin: 1cm)
#set text(font: "Libertinus Serif", size: 9pt)

#let sales = (product: ("Bolt", "Nut"), units: (1250, 860))

#grid(
  columns: 3,
  gutter: 1cm,

  // No notes at all: the closing rule belongs to the last body row.
  display-table(sales, table-header(title: [No notes]), format-integer("units")),

  // A summary closes the table instead.
  display-table(
    sales,
    table-header(title: [Summary last]),
    format-integer("units"),
    grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units",)),
  ),

  // Notes close the table, marked and unmarked together.
  display-table(
    sales,
    table-header(title: [Notes last]),
    format-integer("units"),
    table-footnote([Marked.], locations: cells-column-labels(columns: "units")),
    table-footnote([Unmarked.]),
    table-source-note([Source: ledger.]),
  ),
)

#v(1em)

// Booktabs, which is nothing but rules, on a table with no notes.
#display-table(sales, format-integer("units"), theme: theme-booktabs())
