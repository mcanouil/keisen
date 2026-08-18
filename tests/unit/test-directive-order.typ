// Directive order is free: validation and ordering run once on the folded spec,
// so no directive depends on being written before or after another.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-align, columns-combine, columns-hide, columns-label, columns-move
#import "../../src/parts/spanners.typ": table-spanner
#import "../../src/parts/stub.typ": table-stub

#let data = (city: (1,), highway: (2,), price: (3,), notes: ("x",))

// --- a move reads the same either way round ---

#let hide-first = build-spec(
  data,
  (columns-hide("notes"), columns-move("price", before: "city")),
  (:),
)
#let move-first = build-spec(
  data,
  (columns-move("price", before: "city"), columns-hide("notes")),
  (:),
)
#assert.eq(hide-first.columns, ("price", "city", "highway"))
#assert.eq(move-first.columns, hide-first.columns)

// The other half of the guarantee, that a move anchored on a hidden or promoted
// column fails the same way whichever order it is written in, lives in
// tests/expect-fail/: Typst has no try, so a panic is asserted by compiling a
// document that must not compile.

// --- a move is unaffected by where the stub directive sits ---

#let stub-first = build-spec(
  data,
  (table-stub(rowname: "city"), columns-move("price", after: "highway")),
  (:),
)
#assert.eq(stub-first.columns, ("highway", "price", "notes"))

#let stub-last = build-spec(
  data,
  (columns-move("price", after: "highway"), table-stub(rowname: "city")),
  (:),
)
#assert.eq(stub-last.columns, stub-first.columns)

// --- several moves apply in the order they were written ---

#let chained = build-spec(
  data,
  (columns-move("price", before: "city"), columns-move("notes", before: "price")),
  (:),
)
#assert.eq(chained.columns, ("notes", "price", "city", "highway"))

// --- a spanner validates against the final order, whichever side it is on ---

#let spanner-first = build-spec(
  data,
  (table-spanner([Mileage], ("city", "highway")), columns-move("price", before: "city")),
  (:),
)
#assert.eq(spanner-first.columns, ("price", "city", "highway", "notes"))

#let spanner-last = build-spec(
  data,
  (columns-move("price", before: "city"), table-spanner([Mileage], ("city", "highway"))),
  (:),
)
#assert.eq(spanner-last.columns, spanner-first.columns)

// --- labels are unaffected by where the move sits ---

#let labelled = build-spec(
  data,
  (columns-move("price", before: "city"), columns-label(price: [Price])),
  (:),
)
#assert.eq(labelled.labels.price, [Price])

// --- an alignment reaches a column the fold had not built yet ---

#let paired = (estimate: (1.2,), error: (0.1,))
#let pattern = (value, spread) => [#value (#spread)]

#let combine-first = build-spec(
  paired,
  (columns-combine("effect", ("estimate", "error"), pattern), columns-align(end)),
  (:),
)
#assert.eq(combine-first.align, (effect: end))

#let align-first = build-spec(
  paired,
  (columns-align(end), columns-combine("effect", ("estimate", "error"), pattern)),
  (:),
)
#assert.eq(align-first.align, combine-first.align)

// --- the last alignment written wins, whichever spelling it is ---

#let sales = (units: (1,), price: (2,))

#let named-last = build-spec(
  sales,
  (columns-align(center), columns-align(end, columns: "units")),
  (:),
)
#assert.eq(named-last.align, (units: end, price: center))

#let blanket-last = build-spec(
  sales,
  (columns-align(end, columns: "units"), columns-align(center)),
  (:),
)
#assert.eq(blanket-last.align, (units: center, price: center))

// --- a selector that filters never reaches the stub ---
//
// The stub leaves the column list, and a filter reads that list, so only a name
// spelled out addresses it. Written either way round, so the rule is the rule
// rather than an accident of where the stub directive sits.

#let filtered-stub = build-spec(
  (product: ("Bolt",), units: (1,)),
  (table-stub(rowname: "product"), columns-align(center)),
  (:),
)
#assert.eq(filtered-stub.align, (units: center))

#let filtered-stub-last = build-spec(
  (product: ("Bolt",), units: (1,)),
  (columns-align(center), table-stub(rowname: "product")),
  (:),
)
#assert.eq(filtered-stub-last.align, filtered-stub.align)

#let named-stub = build-spec(
  (product: ("Bolt",), units: (1,)),
  (table-stub(rowname: "product"), columns-align(end, columns: "product")),
  (:),
)
#assert.eq(named-stub.align, (product: end))
