// Dates and markup, the two formatters that produce opaque content rather than
// alignment slots: there is no decimal point in either, so both follow the
// column alignment like any other text.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    release: ("0.1.0", "0.2.0", "0.3.0"),
    // Both spellings of an ISO instant, and a datetime the document built.
    published: ("2026-03-01", "2026-06-17T09:30:00", datetime(year: 2026, month: 8, day: 14)),
    // Typst markup carried as text, which is how a generator emits emphasis.
    summary: (
      "First release, *unstable*.",
      "Adds `format-currency` and friends.",
      "_Nanoplots_ drawn natively.",
    ),
  ),
  table-header(title: [Release history]),
  table-stub(rowname: "release", label: [Version]),
  columns-label(published: [Published], summary: [Summary]),
  format-date("published", pattern: "[day] [month repr:long] [year]"),
  format-markup("summary"),
  table-source-note([Source: the changelog.]),
  theme: theme-booktabs(),
)
