// Row-store normalisation: column stores convert, every row carries _index.

#import "../../src/data.typ": normalise, column, column-names

// --- column store to row store ---

#let rows = normalise((mass: (1, 2), name: ("a", "b")))
#assert.eq(rows.len(), 2)
#assert.eq(rows.first().mass, 1)
#assert.eq(rows.last().name, "b")

// --- reserved position key ---

#assert.eq(rows.first()._index, 0)
#assert.eq(rows.last()._index, 1)

// --- row store passes through, gaining _index ---

#let given = normalise(((mass: 3), (mass: 4)))
#assert.eq(given.map(row => row._index), (0, 1))
#assert.eq(given.map(row => row.mass), (3, 4))

// --- column readers ---

#assert.eq(column-names(rows), ("mass", "name"))
#assert.eq(column(rows, "name"), ("a", "b"))

// --- degenerate inputs ---

#assert.eq(normalise(()), ())
#assert.eq(normalise((:)), ())
#assert.eq(column-names(()), ())

// --- sparse rows are missing values, not failures ---

#assert.eq(column(normalise(((a: 1), (b: 2))), "a"), (1, none))
