// A stub group column is drawn as a row label across the whole table, so it has
// no cell of its own to align. The row-name column beside it does take one.
// expect: columns-align: column region is the stub's group column
// expect: Only the row-name column takes an alignment; a group column is drawn as a row label across the table.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-align
#import "../../src/parts/stub.typ": table-stub

#build-spec(
  (product: ("Bolt",), region: ("North",), units: (1,)),
  (table-stub(rowname: "product", group: "region"), columns-align(end, columns: "region")),
  (:),
)
