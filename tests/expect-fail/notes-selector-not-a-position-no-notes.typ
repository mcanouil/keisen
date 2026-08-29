// Whether a selector is usable does not depend on what the table turned out to
// hold. The matchers see one candidate at a time, so a table with no notes ran
// none of them and the selector went unread, which is where a caller has least
// to go on.
// expect: notes: selector must be auto, a note position, an array of positions, or a predicate
// expect: got "1".
// expect: Notes are numbered from zero, in the order the footer prints them.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: (1, 2)),
  table-style(style(fill: red), locations: cells-source-notes(notes: "1")),
)
