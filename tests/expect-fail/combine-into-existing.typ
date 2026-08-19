// Combining into a column that already holds data, and is not one of the
// sources, would replace it without saying so.
// expect: columns-combine: into names an existing column, gene
// expect: Give the combined column a name of its own, or combine into one of its sources.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (gene: ("BRCA1", "TP53"), estimate: (1.2, 3.4), error: (0.1, 0.2)),
  columns-combine("gene", ("estimate", "error"), (value, spread) => [#value (#spread)]),
)
