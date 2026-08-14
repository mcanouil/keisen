// Directive order is free: validation and ordering run once on the folded spec,
// so no directive depends on being written before or after another.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-hide, columns-label, columns-move
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
