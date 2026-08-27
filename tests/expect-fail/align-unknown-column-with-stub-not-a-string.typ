// The hint lists the known columns, and the stub contributes its row-name
// column to that list. Alignment resolves before the folded spec is validated,
// so a stub name that is not a string reaches the hint first, and every name it
// lists is written as it reads.
// expect: columns-align: unknown column typo
// expect: Known columns: 42, product, units.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt", "Nut"), units: (1, 2)),
  table-stub(rowname: 42),
  columns-align(center, columns: "typo"),
)
