// A note selector numbers the footer rows, so a name written among the numbers
// is a typo, and it is answered rather than filtered away.
//
// The message names the rows vocabulary, because a note is addressed by
// position through the same matcher a row is. A bare `notes: "1"` has always
// been answered this way, so an array of them reads the same.
// expect: rows: selector must be auto, an index, an array of indices, or a predicate
// expect: got (0, "1").
// expect: Write 0, (0, 2), or row => row.units > 100.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: (1, 2)),
  table-source-note[First.],
  table-source-note[Second.],
  table-style(style(fill: red), locations: cells-source-notes(notes: (0, "1"))),
)
