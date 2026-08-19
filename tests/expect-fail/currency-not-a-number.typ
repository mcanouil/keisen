// A word in a money column is a data problem worth surfacing, and the error
// names the formatter the caller actually wrote rather than the one it delegates
// to underneath.
// expect: format-currency: value is not a finite number
// expect: got "free".
// expect: Only finite numbers are formatted here; use format() for anything else.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (price: (1.5, "free")),
  format-currency("price"),
)
