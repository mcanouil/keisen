// Each value of a combined column lines up with the same value in the other
// rows, on its own decimal separator, and the text between the values lines up
// too. A bold row, a value the pattern sets in bold, and a missing bound keep
// the column straight; a row the pattern writes differently keeps its own
// content.

#import "/lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    term: ("Treatment", "Age, per 10 years", "Body mass index", "Current smoker", "Region"),
    estimate: (-0.42, 0.18, 10.09, 0.21, 1.2),
    lower: (-0.61, 0.07, 9.04, none, 0.4),
    upper: (-0.23, 0.29, 11.14, 0.44, 2.0),
    mean: (12.5, 3.25, 104.0, 0.5, 7.0),
    sd: (1.2, 0.85, 12.75, 0.05, 1.0),
  ),
  table-stub(rowname: "term", label: [Term]),
  format-number(("estimate", "lower", "upper"), decimals: 2),
  format-number(("mean", "sd"), decimals: 2),
  substitute-missing("lower", replacement: [n.e.]),
  columns-combine(
    "interval",
    ("estimate", "lower", "upper"),
    (estimate, lower, upper) => [#strong(estimate) (#lower, #upper)],
    label: [Estimate (95% CI)],
  ),
  columns-combine(
    "spread",
    ("mean", "sd"),
    (mean, sd) => if sd == [1.00] [#mean] else [#mean #sym.plus.minus #sd],
    label: [Mean ± SD],
  ),
  table-style(
    style(text: (weight: "bold")),
    locations: cells-body(columns: "spread", rows: row => row.term == "Age, per 10 years"),
  ),
  theme: theme-booktabs(),
)
