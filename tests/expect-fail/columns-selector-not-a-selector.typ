// Every directive that names columns takes the same selector, and a number is
// none of its shapes.
// expect: columns: selector must be auto, a name, an array of names, or a predicate
// expect: got 42.
// expect: Write "units", ("units", "price"), or name => name != "units".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  format-integer(42),
)
