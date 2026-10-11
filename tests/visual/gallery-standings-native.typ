// Gallery: league standings, built in native Typst from the same data.
// Its Keisen twin is gallery-standings-keisen.typ; the two render alike.

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let data = (
  position: (1, 2, 3, 4, 5, 6, 7, 8),
  team: (
    "Ashford",
    "Brampton",
    "Carrow",
    "Dunmore",
    "Elwick",
    "Fenwick",
    "Garth",
    "Hollins",
  ),
  played: (14,) * 8,
  won: (10, 9, 7, 6, 5, 4, 3, 2),
  drawn: (2, 2, 3, 2, 3, 2, 3, 3),
  lost: (2, 3, 4, 6, 6, 8, 8, 9),
  difference: (18, 14, 6, 2, -1, -8, -12, -19),
  points: (32, 29, 24, 20, 18, 14, 12, 9),
  form: (
    (3, 3, 1, 3, 3),
    (3, 1, 3, 3, 0),
    (1, 3, 0, 3, 1),
    (0, 3, 3, 0, 1),
    (1, 0, 3, 1, 0),
    (0, 0, 3, 1, 0),
    (1, 0, 0, 3, 0),
    (0, 1, 0, 0, 0),
  ),
)

#let form(results) = {
  let step = 4em / (results.len() - 1)
  let points = results
    .enumerate()
    .map(((index, value)) => (index * step, 0.8em * (1 - value / 3)))
  box(width: 4em, height: 0.8em, {
    place(curve(
      stroke: 0.6pt,
      curve.move(points.first()),
      ..points.slice(1).map(point => curve.line(point)),
    ))
    for point in points {
      place(dx: point.at(0) - 1pt, dy: point.at(1) - 1pt, circle(
        radius: 1pt,
        fill: black,
        stroke: none,
      ))
    }
  })
}

#let shade(difference) = {
  let scale = gradient.linear(rgb("#ef8a62"), rgb("#f7f7f7"), rgb("#67a9cf"))
  scale.sample((difference + 20) / 40 * 100%)
}

#let last = data.team.len() - 1
#let body = ()
#for row in range(data.team.len()) {
  let zone = if row < 2 { rgb("#e5f5e0") } else if row == last {
    rgb("#fee0d2")
  } else { none }
  let difference = data.difference.at(row)
  let signed = if difference > 0 { "+" + str(difference) } else {
    str(difference)
  }
  body += (
    str(data.position.at(row)),
    data.team.at(row),
    ..("played", "won", "drawn", "lost").map(column => str(
      data.at(column).at(row),
    )),
    table.cell(
      fill: if zone == none { shade(difference) } else { zone },
      signed,
    ),
    str(data.points.at(row)),
    form(data.form.at(row)),
  ).map(cell => if type(cell) == content and cell.func() == table.cell {
    cell
  } else { table.cell(fill: zone, cell) })
}

#table(
  columns: 9,
  align: (start, start, end, end, end, end, end, end, start),
  stroke: none,
  inset: 0.5em,
  table.hline(stroke: 0.8pt + luma(60)),
  table.cell(colspan: 9, align: start, text(
    size: 1.1em,
    weight: "bold",
  )[League table]),
  table.cell(colspan: 9, align: start)[After 14 rounds],
  table.header(
    [], [*Team*], [*P*], [*W*], [*D*], [*L*], [*GD*], [*Pts*], [*Last five*],
    table.hline(stroke: 0.5pt + luma(120)),
  ),
  ..body,
  table.hline(stroke: 0.5pt + luma(180)),
  table.cell(colspan: 9, align: start, text(
    size: 0.8em,
  )[Top two promoted; bottom team relegated.]),
  table.hline(stroke: 0.8pt + luma(60)),
)
