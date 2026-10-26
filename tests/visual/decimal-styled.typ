// A bold row stays on the decimal separator of the rows around it, and so does
// a bold grand total.

#import "/lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    term: ("Alpha", "Beta", "Gamma", "Delta"),
    value: (1111.11, -0.42, 18.0, 1111.11),
  ),
  table-stub(rowname: "term"),
  format-number("value", decimals: 2),
  grand-summary-rows(functions: ("Total": aggregate-sum), columns: "value"),
  table-style(
    style(text: (weight: "bold")),
    locations: cells-body(columns: "value", rows: row => row.term in ("Beta", "Delta")),
  ),
  table-style(style(text: (weight: "bold")), locations: cells-grand-summary(columns: "value")),
  theme: theme-booktabs(),
)
