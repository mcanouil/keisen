// A row selector numbers rows, so a name written among the numbers is a typo.
// The bare value was already refused; an array of them was not.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got (0, "2").
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: (1, 2), price: (3, 4)),
  table-style(style(fill: red), locations: cells-body(rows: (0, "2"))),
)
