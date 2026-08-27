// The third field, on a table whose data holds no rows. A column store names its
// columns even when it holds none, so the table renders and the row matcher ran
// against nothing.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got "1".
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: ()),
  table-style(style(fill: red), locations: cells-body(rows: "1")),
)
