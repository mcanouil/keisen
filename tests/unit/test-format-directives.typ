// Format directives are tagged dictionaries; application picks the last
// directive whose selectors match each cell.

#import "../../src/format/number.typ": format, format-integer, format-number
#import "../../src/format/apply.typ": apply-formats, matches-column, matches-row

// --- selectors ---

#assert.eq(matches-column(auto, "mass"), true)
#assert.eq(matches-column("mass", "mass"), true)
#assert.eq(matches-column("mass", "name"), false)
#assert.eq(matches-column(("mass", "name"), "name"), true)
#assert.eq(matches-column(name => name.starts-with("m"), "mass"), true)

#let row = (mass: 2, _index: 1)
#assert.eq(matches-row(auto, row), true)
#assert.eq(matches-row(1, row), true)
#assert.eq(matches-row(0, row), false)
#assert.eq(matches-row((0, 1), row), true)
#assert.eq(matches-row(candidate => candidate.mass > 1, row), true)

// --- directive shape ---

#let directive = format-number("mass", decimals: 1)
#assert.eq(directive.kind, "format")
#assert.eq(directive.columns, "mass")
#assert.eq(directive.rows, auto)

// --- application ---

#let rows = ((mass: 1.25, _index: 0), (mass: 2.5, _index: 1))

#let cells = apply-formats(rows, (directive,), "mass")
#assert.eq(cells.first().integer, "1")
#assert.eq(cells.first().fraction, "3")
#assert.eq(cells.last().fraction, "5")

// An arbitrary formatter receives the raw value alone.
#let custom = format("mass", value => [#value])
#assert.eq(apply-formats(rows, (custom,), "mass").first(), [1.25])

// Later directives replace earlier ones rather than composing with them.
#let both = apply-formats(rows, (directive, format-integer("mass")), "mass")
#assert.eq(both.first().fraction, "")
#assert.eq(both.first().integer, "1")

// A directive that matches no column leaves the value untouched.
#assert.eq(apply-formats(rows, (format-number("other"),), "mass").first(), 1.25)

// Row selectors narrow the application to part of a column.
#let partial = apply-formats(rows, (format-number("mass", rows: 1, decimals: 0),), "mass")
#assert.eq(partial.first(), 1.25)
#assert.eq(partial.last().integer, "3")
