// The shared domain is the whole justification for a nanoplot, so these fix
// where it comes from: the column being formatted, never an argument the caller
// has to keep in step with it.

#import "../../lib.typ": (
  aggregate-count, format-nanoplot, grand-summary-rows, nanoplot-bar, nanoplot-line, nanoplot-points,
  table-stub,
)
#import "../../src/format/apply.typ": apply-formats, nanoplot-columns
#import "../../src/format/nanoplot.typ": nanoplot-cell, shared-domain
#import "../../src/parts/summaries.typ": summary-values
#import "../../src/spec.typ": build-spec

#let trends = (
  (1.0, 1.2, 1.1, 1.4, 1.8, 2.1),
  (2.0, 1.8, 1.6, 1.5, 1.2, 0.9),
  (1.5, 1.5, 1.6, 1.5, 1.7, 1.6),
)

// The domain spans every reading in the column, not each cell's own range.
#assert.eq(shared-domain(trends), (0.9, 2.1))
#assert.eq(shared-domain(trends, given: (0, 3)), (0, 3))
#assert.eq(shared-domain(()), none)
#assert.eq(shared-domain(((),)), none)

// Decimals and integers are readings like any other.
#assert.eq(shared-domain(((1, decimal("2.5")),)), (1.0, 2.5))

// Values that are not readings are skipped rather than refused: a gap in a
// series is a gap, and substitute-missing has already had its chance.
#assert.eq(shared-domain(((1.0, none, 3.0),)), (1.0, 3.0))

#let directive = format-nanoplot("trend", plot: nanoplot-line)
#assert.eq(directive.kind, "format")
#assert.eq(directive.columns, "trend")
#assert.eq(directive.rows, auto)

// The directive carries its options rather than a closure built over values the
// caller supplied, which is what lets the column decide the domain.
#assert.eq(directive.nanoplot.plot, nanoplot-line)
#assert.eq(directive.nanoplot.domain, auto)
#assert("values" not in directive)

// A nanoplot column formats from the column it names. Passing another column's
// readings is not merely reported: there is nowhere left to pass them.
#let rows = trends.enumerate().map(((index, series)) => (trend: series, other: (0.0, 100.0), _index: index))
#let cells = apply-formats(rows, (directive,), "trend")
#assert.eq(cells.len(), 3)
#for cell in cells { assert.eq(type(cell), content) }

// An explicit domain still wins, since a column is sometimes read against a
// scale that is not its own.
#let fixed = format-nanoplot("trend", plot: nanoplot-line, domain: (0, 10))
#assert.eq(fixed.nanoplot.domain, (0, 10))

// A cell holding no readings draws nothing rather than an empty box of ink.
#assert.eq(nanoplot-cell(directive.nanoplot, (0.9, 2.1))(()), [])
#assert.eq(nanoplot-cell(directive.nanoplot, (0.9, 2.1))(none), [])

#assert.eq(nanoplot-columns((directive,), ("trend", "other")), ("trend",))
#assert.eq(nanoplot-columns((), ("trend",)), ())

// A summary over every column leaves the nanoplots out rather than aggregating
// arrays: `aggregate-count` would otherwise happily count them and hand the
// total to a renderer. Naming the column instead is an error, pinned in
// tests/expect-fail/nanoplot-summarised.typ.
#let summarised = build-spec(
  (asset: ("Equities", "Bonds"), trend: trends.slice(0, 2), weight: (0.62, 0.31)),
  (
    table-stub(rowname: "asset"),
    format-nanoplot("trend", plot: nanoplot-line),
    grand-summary-rows(functions: (Total: aggregate-count)),
  ),
  (:),
)
#let totals = summary-values(summarised).grand.first().values
#assert.eq(totals.keys(), ("weight",))

// Every renderer draws at the sparkline height the design asks for, which the
// gribouille versions could not: they refused a canvas below half a centimetre.
#for plot in (nanoplot-line, nanoplot-bar, nanoplot-points) {
  assert.eq(type(plot((1.0, 2.0, 1.5), domain: (1.0, 2.0), width: 4em, height: 0.8em)), content)
  // A flat series has no span to divide by, and a single reading no line to
  // draw; both draw something rather than failing.
  assert.eq(type(plot((2.0, 2.0, 2.0), domain: (2.0, 2.0), width: 4em, height: 0.8em)), content)
  assert.eq(type(plot((2.0,), domain: (2.0, 2.0), width: 4em, height: 0.8em)), content)
  assert.eq(type(plot((), width: 4em, height: 0.8em)), content)
  // A renderer called by hand, outside format-nanoplot, has no shared domain.
  assert.eq(type(plot((1.0, 2.0, 1.5), width: 4em, height: 0.8em)), content)
}
