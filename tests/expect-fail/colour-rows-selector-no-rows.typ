// The rows of a colour directive, on a table whose data holds no rows. The
// palette is stretched over the rows the selector picks, and the selector is
// read before there is anything to pick from.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got "1".
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: ()),
  data-colour(blue, columns: "units", rows: "1"),
)
