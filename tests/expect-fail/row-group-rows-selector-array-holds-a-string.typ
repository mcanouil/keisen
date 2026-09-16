// A name written among the row numbers is a selector of the wrong kind, and it
// is answered as one. The directive used to call it a row that is not in the
// data, which names a row that was never a row.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got (0, "1").
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (country: ("Denmark", "Spain"), units: (1, 2)),
  table-row-group([Nordics], (0, "1")),
)
