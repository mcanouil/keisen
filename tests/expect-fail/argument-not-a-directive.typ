// Every positional argument after the data is a directive, which is a
// dictionary carrying a kind. Anything else was read for a kind it had not got.
// expect: display-table: argument is not a directive
// expect: got "columns-hide".
// expect: Pass directives such as table-header() or format-number().
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  "columns-hide",
)
