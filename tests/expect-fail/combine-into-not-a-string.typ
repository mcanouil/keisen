// The combined column is addressed by name afterwards, by a label, a spanner or
// a move, so `into` must be a string.
// expect: columns-combine: into must be the name of the column to build
// expect: got 42.
// expect: Give a column name as a string.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (estimate: (1.0,), error: (0.1,)),
  columns-combine(42, ("estimate", "error"), (value, spread) => [#value (#spread)]),
)
