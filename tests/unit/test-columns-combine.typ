// One column built from several. The pattern receives the formatted content of
// its sources, which is what makes `(estimate, error) => [#estimate (#error)]`
// read the way it is written: the combine stage sits after formatting, so the
// pattern never sees a raw value it would have to format itself.

#import "../../lib.typ": (
  aggregate-sum, columns-combine, columns-label, format-number, grand-summary-rows, table-stub,
)
#import "../../src/render/layout.typ": column-cells
#import "../../src/spec.typ": build-spec

#let data = (
  gene: ("BRCA1", "TP53"),
  estimate: (1.234, -0.567),
  error: (0.021, 0.043),
)

#let spec = build-spec(
  data,
  (
    format-number("estimate", decimals: 2),
    format-number("error", decimals: 3),
    columns-combine("effect", ("estimate", "error"), (value, margin) => [#value (#margin)]),
  ),
  (:),
)

// The combined column takes the place of the first of its sources, so it sits
// where a reader was already looking.
#assert.eq(spec.columns, ("gene", "effect"))

// The sources stay readable by predicates and formatters even though they are
// no longer shown, exactly as a hidden column does.
#assert.eq(spec.hidden, ("estimate", "error"))

#let cells = column-cells(spec)

// Compared by what the cell holds rather than by how the pattern's pieces
// happen to nest: the same words in the same order are the same cell.
#let holds(cell, ..parts) = {
  let text = repr(cell)
  let at = 0
  for part in parts.pos() {
    let found = text.position(part)
    assert(found != none, message: part + " is missing from " + text)
    assert(found >= at, message: part + " is out of order in " + text)
    at = found
  }
}

// Each source keeps the formatting its own directive gave it: the estimate to
// two decimals, the error to three.
#holds(cells.at(1).first(), "1.23", "0.021")
#holds(cells.at(1).last(), "-0.57", "0.043")

// A combined cell is content, so it carries no slots to line up on: a combined
// column is opaque, which is the price of the pattern being free-form.
#assert.eq(type(cells.at(1).first()), content)

// The label defaults to the name the column was given, and columns-label names
// it like any other.
#assert.eq(spec.labels.at("effect", default: none), none)

#let labelled = build-spec(
  data,
  (
    columns-combine("effect", ("estimate", "error"), (value, margin) => [#value (#margin)], label: [Effect]),
    columns-label(gene: [Gene]),
  ),
  (:),
)
#assert.eq(labelled.labels.effect, [Effect])
#assert.eq(labelled.labels.gene, [Gene])

// Keeping the sources is a choice: a table that shows both the parts and the
// combination is a table, not a mistake.
#let kept = build-spec(
  data,
  (columns-combine("effect", ("estimate", "error"), (value, margin) => [#value], hide-sources: false),),
  (:),
)
#assert.eq(kept.columns, ("gene", "effect", "estimate", "error"))
#assert.eq(kept.hidden, ())

// Combining into one of the sources is the ordinary case, and it does not
// collide with itself.
#let merged = build-spec(
  data,
  (columns-combine("estimate", ("estimate", "error"), (value, margin) => [#value ± #margin]),),
  (:),
)
#assert.eq(merged.columns, ("gene", "estimate"))
#assert.eq(merged.hidden, ("error",))
#holds(column-cells(merged).at(1).first(), "1.234", "0.021")

// A combined column holds no data, so a summary over every column leaves it
// out rather than aggregating a column that is not there.
#let summarised = build-spec(
  data,
  (
    table-stub(rowname: "gene"),
    columns-combine("effect", ("estimate", "error"), (value, margin) => [#value]),
    grand-summary-rows(functions: (Total: aggregate-sum)),
  ),
  (:),
)
#assert.eq(summarised.grand-summaries.len(), 1)
