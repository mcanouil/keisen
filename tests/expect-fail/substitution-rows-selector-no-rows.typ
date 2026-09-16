// The rows of a substitution, on a table whose data holds no rows. The columns
// half was held to the kind it reads and the rows half was not.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got "1".
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: ()),
  substitute-missing("units", rows: "1"),
)
