// Spanners label adjacent columns, stack in levels, and are validated against
// the final column order rather than at the moment they are written.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-move
#import "../../src/parts/spanners.typ": spanner-rows, table-spanner

#let data = (city: (1,), highway: (2,), price: (3,))

#let spec = build-spec(
  data,
  (table-spanner([Mileage], ("city", "highway")),),
  (:),
)

#assert.eq(spec.spanners.len(), 1)
#assert.eq(spec.spanners.first().label, [Mileage])
#assert.eq(spec.spanners.first().columns, ("city", "highway"))
#assert.eq(spec.spanners.first().level, 1)

// A spanner row covers its columns and leaves gaps over the others.
#let rows = spanner-rows(spec)
#assert.eq(rows.len(), 1)
#assert.eq(rows.first().map(cell => cell.span), (2, 1))
#assert.eq(rows.first().first().label, [Mileage])
#assert.eq(rows.first().last().label, none)

// Order is decided by the final column list, so a later move still validates.
#let moved = build-spec(
  data,
  (table-spanner([Mileage], ("city", "highway")), columns-move("price", before: "city")),
  (:),
)
#assert.eq(moved.columns, ("price", "city", "highway"))
#assert.eq(spanner-rows(moved).first().map(cell => cell.span), (1, 2))

// Two spanners on one level sit in the same row.
#let two = build-spec(
  data,
  (table-spanner([Mileage], ("city", "highway")), table-spanner([Cost], ("price",))),
  (:),
)
#assert.eq(spanner-rows(two).len(), 1)
#assert.eq(spanner-rows(two).first().map(cell => cell.span), (2, 1))

// Levels stack, highest level first, so a spanner may span spanners.
#let stacked = build-spec(
  data,
  (
    table-spanner([Mileage], ("city", "highway")),
    table-spanner([Everything], ("city", "highway", "price"), level: 2),
  ),
  (:),
)
#assert.eq(spanner-rows(stacked).len(), 2)
#assert.eq(spanner-rows(stacked).first().map(cell => cell.span), (3,))
#assert.eq(spanner-rows(stacked).last().map(cell => cell.span), (2, 1))

// No spanners, no rows.
#assert.eq(spanner-rows(build-spec(data, (), (:))), ())
