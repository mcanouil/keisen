// A rows selector addresses positions rather than names, so a string is none of
// its shapes.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got "first".
// expect: Write 0, (0, 2), or row => row.units > 100.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  format-integer("units", rows: "first"),
)
