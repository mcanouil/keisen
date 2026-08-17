// The benchmark table: 2000 rows and 10 columns, styled and formatted.
//
// This is not a test. It lives beside the script that compiles it rather than
// under tests/, because a test page grows to fit its content and this one must
// not: paging a long table is part of the cost being measured, so the geometry
// stays a real page.
//
// `--input rows=<n>` sets the row count, so the same document measures the
// growth curve rather than one point on it.

#import "../lib.typ": *

#set page(paper: "a4", margin: 2cm)
#set text(font: "Libertinus Serif", size: 9pt)
#show figure: set block(breakable: true)

#let rows = int(sys.inputs.at("rows", default: "2000"))

// Deterministic values, so the same row count renders the same table on every
// run and two timings measure the compiler rather than the data.
#let spread(index, modulus, offset) = calc.rem(index * 7919 + offset, modulus)

#let regions = ("North", "South", "East", "West")
#let grades = ("A", "B", "C")

#let data = (
  product: range(rows).map(index => "Item " + str(index)),
  region: range(rows).map(index => regions.at(calc.rem(index, regions.len()))),
  grade: range(rows).map(index => grades.at(spread(index, grades.len(), 0))),
  units: range(rows).map(index => spread(index, 9000, 100)),
  revenue: range(rows).map(index => spread(index, 500000, 250) / 100),
  margin: range(rows).map(index => spread(index, 400, 3) / 1000),
  growth: range(rows).map(index => (spread(index, 2000, 17) - 1000) / 100),
  payload: range(rows).map(index => spread(index, 900000000, 4096)),
  measured: range(rows).map(index => datetime(
    year: 2020 + spread(index, 5, 1),
    month: 1 + spread(index, 12, 2),
    day: 1 + spread(index, 28, 3),
  )),
  reading: range(rows).map(index => spread(index, 1000000, 11) / 1000000000),
)

#display-table(
  data,
  table-header(
    title: [Benchmark],
    subtitle: [Two thousand rows through every stage of the pipeline],
  ),
  table-stub(rowname: "product", group: "region", label: [Product]),
  columns-label(
    grade: [Grade],
    units: [Units],
    revenue: [Revenue],
    margin: [Margin],
    growth: [Growth],
    payload: [Payload],
    measured: [Measured],
    reading: [Reading],
  ),
  table-spanner([Trade], ("units", "revenue", "margin")),
  table-spanner([Signal], ("payload", "measured", "reading")),
  format-integer("units"),
  format-currency("revenue", currency: "EUR", decimals: 2),
  format-percent("margin", decimals: 1),
  format-number("growth", decimals: 2),
  format-bytes("payload"),
  format-date("measured", pattern: "[year]-[month]-[day]"),
  format-scientific("reading", decimals: 3),
  substitute-zero("growth", replacement: [--]),
  data-colour(("#f7fbff", "#08519c"), columns: "units"),
  table-style(
    style(text: (fill: rgb("#b2182b"), weight: "bold")),
    locations: cells-body(columns: "margin", rows: row => row.margin < 0.05),
  ),
  table-style(
    style(fill: rgb("#fff5eb")),
    locations: cells-body(columns: "growth", rows: row => row.growth < 0),
  ),
  summary-rows(functions: (Total: aggregate-sum), columns: ("units",)),
  grand-summary-rows(functions: (Overall: aggregate-mean), columns: ("margin", "growth")),
  table-footnote([Units exclude returns.], locations: cells-column-labels(columns: "units")),
  table-source-note([Source: generated figures.]),
)
