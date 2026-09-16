// A rows selector is read whether or not the part it addresses holds anything.
// A format directive reached the matcher one row at a time, so a table with no
// rows never ran it and the selector went unread.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got "1".
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: ()),
  format-integer("units", rows: "1"),
)
