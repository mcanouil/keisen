// Gallery: population by region, built in native Typst from the same data.
// Its Keisen twin is gallery-population-keisen.typ; the two render alike.

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let data = (
  region: (
    "North East",
    "North West",
    "Yorkshire and The Humber",
    "East Midlands",
    "West Midlands",
    "East",
    "London",
    "South East",
    "South West",
  ),
  population: (
    2683040,
    7516113,
    5541262,
    4934939,
    6021653,
    6398497,
    8945309,
    9379833,
    5764881,
  ),
  share: (0.047, 0.131, 0.097, 0.086, 0.105, 0.112, 0.156, 0.164, 0.101),
  profile: (
    (0.17, 0.12, 0.24, 0.27, 0.20),
    (0.18, 0.12, 0.26, 0.26, 0.18),
    (0.19, 0.12, 0.25, 0.25, 0.19),
    (0.18, 0.11, 0.25, 0.26, 0.20),
    (0.19, 0.12, 0.26, 0.25, 0.18),
    (0.18, 0.10, 0.25, 0.27, 0.20),
    (0.20, 0.14, 0.36, 0.20, 0.10),
    (0.18, 0.11, 0.25, 0.27, 0.19),
    (0.16, 0.10, 0.23, 0.28, 0.23),
  ),
  median-age: (42.3, 40.1, 40.4, 41.2, 39.8, 42.0, 35.6, 41.8, 44.5),
)

#let fixed(value, digits) = {
  let text = str(calc.round(value, digits: digits))
  let parts = text.split(".")
  let decimals = parts.at(1, default: "")
  parts.at(0) + "." + decimals + "0" * (digits - decimals.len())
}

#let grouped(number) = {
  let digits = str(calc.abs(number))
  let groups = ()
  while digits.len() > 3 {
    groups.insert(0, digits.slice(-3))
    digits = digits.slice(0, -3)
  }
  groups.insert(0, digits)
  (if number < 0 { "-" } else { "" }) + groups.join(sym.space.thin)
}

#let bars(values) = {
  let peak = calc.max(..values)
  let width = 5em / values.len()
  box(width: 5em, height: 1em, baseline: 25%, stack(
    dir: ltr,
    ..values.map(value => box(width: width, height: 1em, align(
      bottom + center,
      rect(
        width: width * 0.8,
        height: 1em * value / peak,
        fill: black,
        stroke: none,
      ),
    ))),
  ))
}

#let body = ()
#for row in range(data.region.len()) {
  body += (
    data.region.at(row),
    grouped(data.population.at(row)),
    fixed(data.share.at(row) * 100, 1) + " %",
    bars(data.profile.at(row)),
    fixed(data.median-age.at(row), 1),
  )
}

#table(
  columns: 5,
  align: (
    start + horizon,
    end + horizon,
    end + horizon,
    start + horizon,
    end + horizon,
  ),
  stroke: none,
  inset: 0.5em,
  table.hline(stroke: 0.8pt + luma(60)),
  table.cell(colspan: 5, align: start, text(
    size: 1.1em,
    weight: "bold",
  )[Population by region]),
  table.cell(colspan: 5, align: start)[Mid-year estimates, 2025],
  table.header(
    [*Region*],
    [*Population*],
    [*Share of England*],
    [*Age profile*#super[1]],
    [*Median age*],
    table.hline(stroke: 0.5pt + luma(120)),
  ),
  ..body,
  table.hline(stroke: 0.8pt + luma(60)),
  [*Total*], grouped(data.population.sum()), [], [], [],
  table.hline(stroke: 0.5pt + luma(180)),
  table.cell(colspan: 5, align: start, text(
    size: 0.8em,
  )[Source: synthetic census data.]),
  table.cell(colspan: 5, align: start, text(size: 0.8em)[
    #super[1]Bands: 0 to 15, 16 to 24, 25 to 44, 45 to 64, 65 and over.
  ]),
  table.hline(stroke: 0.8pt + luma(60)),
)
