// Column names given positionally read the same written out or given as an
// array.
//
// `columns-hide` and `columns-move` take their names one per argument, and an
// array was neither read nor refused: it reached the error builder, which added
// it to a string and died on a line of this package rather than naming the
// directive the caller wrote. An array is the natural thing to write, since the
// `columns:` selector families take one and the serialised `hidden` key does
// too, so it is read as the whole list.

#import "../../src/parts/columns.typ": columns-hide, columns-move
#import "../../src/spec.typ": build-spec

#let data = (city: (1,), highway: (2,), price: (3,), notes: ("x",))

// --- the directive carries the same names either way ---

#assert.eq(columns-hide(("city", "notes")).columns, ("city", "notes"))
#assert.eq(columns-hide("city", "notes").columns, ("city", "notes"))

// One rule rather than a special case for a single argument: every positional
// array contributes its names, in the order they are written.
#assert.eq(columns-hide("city", ("highway", "notes")).columns, ("city", "highway", "notes"))
#assert.eq(columns-hide().columns, ())

#assert.eq(columns-move(("price", "notes"), before: "city").columns, ("price", "notes"))
#assert.eq(columns-move("price", "notes", before: "city").columns, ("price", "notes"))

// --- the folded spec reads them the same way ---

#let hidden-array = build-spec(data, (columns-hide(("city", "notes")),), (:))
#assert.eq(hidden-array.columns, ("highway", "price"))
#assert.eq(hidden-array.hidden, ("city", "notes"))

#let moved-array = build-spec(data, (columns-move(("price", "notes"), before: "city"),), (:))
#assert.eq(moved-array.columns, ("price", "notes", "city", "highway"))

// The anchor names one column rather than a list, so it takes no array. What a
// non-string anchor is told is pinned in tests/expect-fail/.
#assert.eq(columns-move("price", before: "city").before, "city")
