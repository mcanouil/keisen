// An alignment filters the columns the table ends up with, so a selector that
// is neither a name, an array of names, `auto` nor a predicate is read before
// the filter runs. Every column here is hidden, so the filter ran against
// nothing and the selector went unread.
// expect: columns: selector must be auto, a name, an array of names, or a predicate
// expect: got 42.
// expect: Write "units", ("units", "price"), or name => name != "units".

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: (1, 2)),
  columns-hide("units"),
  columns-align(end, columns: 42),
)
