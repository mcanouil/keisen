// Milestone 4: a table long enough to break, so the column labels and the
// current group label both reprint on the following page.

#import "../../lib.typ": *

// The height is fixed, because a page that grows to hold the table never breaks
// and breaking is what this test is for. The width still fits its content, as
// every other page here does.
#set page(width: auto, height: 9cm, margin: 1cm)
#set text(font: "Libertinus Serif", size: 9pt)

#let count = 22

#display-table(
  (
    station: range(count).map(index => "Station " + str(index + 1)),
    region: range(count).map(index => if index < 11 { "North" } else { "South" }),
    temperature: range(count).map(index => 12.5 + index * 0.75),
    humidity: range(count).map(index => 60 + calc.rem(index * 7, 30)),
  ),
  table-header(title: [Station readings]),
  table-stub(rowname: "station", group: "region", label: [Station]),
  columns-label(temperature: [Temperature], humidity: [Humidity]),
  columns-width(("station": 3.2cm)),
  format-number("temperature", decimals: 2),
  format-integer("humidity"),
  summary-rows(functions: (Mean: aggregate-mean), format: format-number(auto, decimals: 2)),
  table-source-note([Source: station log.]),
)
