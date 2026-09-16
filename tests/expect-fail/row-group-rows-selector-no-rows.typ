// A group declared over a table whose data holds no rows. The directive read its
// own rows one at a time, so the selector went unread, and the table came out
// with no group and no word about why.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got "1".
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: ()),
  table-row-group([Nordics], "1"),
)
