// Column labels reach the PDF as header cells scoped to their column.
//
// The design says the package gets this for free from `table.header`. Free is
// not the same as true, so the counts are exact: one header group, one header
// cell per column label, each scoped to a column.
//
// expect-tag: 1 /S /Table
// expect-tag: 1 /S /THead
// expect-tag: 3 /S /TH
// expect-tag: 3 /Scope /Column

#import "../../lib.typ": *

// PDF/UA-1 wants a title and a language on the document itself, neither of
// which the package owns. They belong to the fixture, not to the table.
#set document(title: [Fuel consumption], author: "keisen")
#set text(lang: "en")

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    model: ("Audi A4", "BMW 320i"),
    consumption: (7.25, 8.5),
    year: (2019, 2021),
  ),
  columns-label(
    model: [Model],
    consumption: [Consumption],
    year: [Year],
  ),
  format-number("consumption", decimals: 2),
  format-integer("year", grouping: none),
)
