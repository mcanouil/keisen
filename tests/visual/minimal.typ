// Milestone 1: title, subtitle, column labels, formatted body, source note.

#import "../../lib.typ": *

#set page(width: 14cm, height: auto, margin: 1cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    model: ("Audi A4", "BMW 320i", "Volkswagen Golf"),
    consumption: (7.25, 8.5, 6.125),
    year: (2019, 2021, 2020),
  ),
  table-header(
    title: [Fuel consumption],
    subtitle: [Litres per 100 kilometres],
  ),
  columns-label(
    model: [Model],
    consumption: [Consumption],
    year: [Year],
  ),
  format-number("consumption", decimals: 2),
  format-integer("year", grouping: none),
  table-source-note([Source: manufacturer figures.]),
)
