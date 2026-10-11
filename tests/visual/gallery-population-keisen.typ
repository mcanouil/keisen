// Gallery: population by region, built with Keisen.
// Its native twin is gallery-population-native.typ; the two render alike.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let data = (
  region: ("North", "North East", "Midlands", "East", "London", "South West"),
  population: (7516113, 2683040, 10737200, 6398497, 8945309, 5764881),
  share: (0.157, 0.056, 0.224, 0.133, 0.187, 0.120),
  profile: (
    (0.18, 0.12, 0.26, 0.26, 0.18),
    (0.17, 0.12, 0.24, 0.27, 0.20),
    (0.19, 0.12, 0.26, 0.25, 0.18),
    (0.18, 0.10, 0.25, 0.27, 0.20),
    (0.20, 0.14, 0.36, 0.20, 0.10),
    (0.16, 0.10, 0.23, 0.28, 0.23),
  ),
  median-age: (40.1, 42.3, 39.8, 42.0, 35.6, 44.5),
)

#display-table(
  data,
  table-header(
    title: [Population by region],
    subtitle: [Mid-year estimates, 2025],
  ),
  table-stub(rowname: "region", label: [Region]),
  columns-label(
    population: [Population],
    share: [Share of England],
    profile: [Age profile],
    median-age: [Median age],
  ),
  format-integer("population"),
  format-percent("share", decimals: 1),
  format-number("median-age", decimals: 1),
  format-nanoplot(
    "profile",
    plot: nanoplot-bar,
    width: 5em,
    height: 1em,
    baseline: 25%,
  ),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: (
    "population",
  )),
  table-footnote(
    [Bands: 0 to 15, 16 to 24, 25 to 44, 45 to 64, 65 and over.],
    locations: cells-column-labels(columns: "profile"),
  ),
  table-source-note([Source: synthetic census data.]),
  table-options(cell-vertical-align: horizon),
)
