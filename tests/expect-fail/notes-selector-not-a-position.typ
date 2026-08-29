// A note is addressed by its position in the footer. The selector used to be
// answered in the rows vocabulary, because a note is matched through the same
// matcher a row is, so the caller was pointed at a field they did not write.
// expect: notes: selector must be auto, a note position, an array of positions, or a predicate
// expect: got "1".
// expect: Notes are numbered from zero, in the order the footer prints them.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: (1, 2)),
  table-source-note[First.],
  table-source-note[Second.],
  table-style(style(fill: red), locations: cells-source-notes(notes: "1")),
)
