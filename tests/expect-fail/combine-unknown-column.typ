// A source that exists in no row is a typo, and combining silently around it
// would leave the pattern reading a column of nothing.
// expect: columns-combine: unknown column margin

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (estimate: (1.2, 3.4), error: (0.1, 0.2)),
  columns-combine("effect", ("estimate", "margin"), (value, spread) => [#value (#spread)]),
)
