// Indentation is leading space before the row name, and an alignment other than
// start absorbs it, so every level would render flush against the same edge.
// expect: columns-align: an indented stub is start-aligned
// expect: The indent column sets the depth of each row name, which any other alignment would flatten.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-align
#import "../../src/parts/stub.typ": table-stub

#build-spec(
  (item: ("Total", "North"), depth: (0, 1), units: (100, 60)),
  (table-stub(rowname: "item", indent: "depth"), columns-align(end, columns: "item")),
  (:),
)
