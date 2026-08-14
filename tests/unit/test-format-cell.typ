// A row-aware formatter. Every other formatter sees the value alone, so a cell
// that depends on its neighbours has no way to reach them; this is the escape
// hatch, and the row it receives is the input row, hidden columns and the
// reserved _index key included.

#import "../../src/format/number.typ": format-cell, format-number
#import "../../src/format/apply.typ": apply-formats
#import "../../src/render/layout.typ": covering

#let rows = (
  (mass: 2, symbol: "Fe", _index: 0),
  (mass: 5, symbol: "Pb", _index: 1),
)

// --- directive shape ---

#let directive = format-cell("mass", row => [#row.symbol])
#assert.eq(directive.kind, "format")
#assert.eq(directive.columns, "mass")
#assert.eq(directive.rows, auto)
#assert.eq(directive.cell, true)

// A plain format directive carries the same key, saying it is not row-aware.
#assert.eq(format-number("mass").cell, false)

// --- application ---

#assert.eq(apply-formats(rows, (directive,), "mass").first(), [Fe])
#assert.eq(apply-formats(rows, (directive,), "mass").last(), [Pb])

// The row carries what the column cannot: another column, and the row position.
#let neighbour = format-cell("mass", row => [#(row.symbol + " " + str(row.mass))])
#assert.eq(apply-formats(rows, (neighbour,), "mass").last(), [Pb 5])
#assert.eq(apply-formats(rows, (format-cell("mass", row => [#(row._index)]),), "mass").last(), [1])

// Row selectors narrow it as they narrow everything else.
#let partial = apply-formats(rows, (format-cell("mass", row => [#(row.symbol)], rows: 1),), "mass")
#assert.eq(partial.first(), 2)
#assert.eq(partial.last(), [Pb])

// The last matching directive wins across kinds, as it does within one.
#let replaced = apply-formats(rows, (format-number("mass", decimals: 1), directive), "mass")
#assert.eq(replaced.first(), [Fe])

// --- summaries ---

// A summary cell is an aggregate of a column, so there is no row to read. A
// cell formatter therefore covers no column, and the summary falls back to
// whichever plain directive does.
#assert.eq(covering((directive,), "mass").len(), 0)
#assert.eq(covering((format-number("mass"),), "mass").len(), 1)
