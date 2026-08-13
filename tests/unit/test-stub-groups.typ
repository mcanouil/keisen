// Grouping, indentation, and the stubhead label, including the shapes that
// used to reach the data layer or the renderer before anyone checked them.

#import "../../lib.typ": display-table
#import "../../src/data.typ": group-rows, normalise
#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-label, columns-move
#import "../../src/parts/stub.typ": table-stub

// --- grouping keeps first-appearance order and carries row positions ---

#let rows = normalise((region: ("South", "North", "South")))
#assert.eq(group-rows(rows, "region").map(group => group.label), ("South", "North"))
#assert.eq(group-rows(rows, "region").first().rows, (0, 2))
#assert.eq(group-rows(rows, none), ())

// Numbers label groups as readily as strings.
#assert.eq(group-rows(normalise((year: (2025, 2024))), "year").map(group => group.label), ("2025", "2024"))

// --- moving columns is resolved against the final column list ---

#let moved = build-spec(
  (city: (1,), highway: (2,), price: (3,)),
  (columns-move("price", before: "city"),),
  (:),
)
#assert.eq(moved.columns, ("price", "city", "highway"))

// --- the stub keeps its columns out of the data columns ---

#let stubbed = build-spec(
  (product: ("Bolt",), region: ("North",), units: (10,)),
  (table-stub(rowname: "product", group: "region"),),
  (:),
)
#assert.eq(stubbed.columns, ("units",))
#assert.eq(stubbed.data-columns, ("product", "region", "units"))
#assert.eq(stubbed.groups.map(group => group.label), ("North",))

// A hidden column stays a data column, which is how a spanner can tell a hidden
// column from a name nobody has.
#assert.eq(stubbed.data.first().product, "Bolt")

// --- labelling the stub column, either spelling ---

#let labelled = build-spec(
  (product: ("Bolt",), units: (10,)),
  (table-stub(rowname: "product"), columns-label(product: [Product])),
  (:),
)
#assert.eq(labelled.labels.product, [Product])
#assert.eq(type(display-table(spec: labelled)), content)
