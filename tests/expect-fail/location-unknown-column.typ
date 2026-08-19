// A location naming a column that does not exist is a typo, and a style aimed
// at nothing would otherwise be dropped in silence.
// expect: cells-body: unknown column typo
// expect: Known columns: units, price.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-style(style(fill: aqua), locations: cells-body(columns: "typo")),
)
