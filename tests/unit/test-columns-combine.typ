// One column built from several. The pattern receives the formatted content of
// its sources, which is what makes `(estimate, error) => [#estimate (#error)]`
// read the way it is written: the combine stage sits after formatting, so the
// pattern never sees a raw value it would have to format itself.

#import "../../lib.typ": (
  aggregate-sum, columns-combine, columns-hide, columns-label, columns-move, format-number,
  grand-summary-rows, table-stub,
)
#import "../../src/render/layout.typ": column-cells, slots-to-content
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
  let text = repr(slots-to-content(cell))
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
#holds(cells.at(1).last(), "\u{2212}0.57", "0.043")

// A combined cell is split into its values and the glue between them, so each
// value can line up down the column. It keeps what the pattern returned, which
// is what it renders as when nothing is lined up.
#let first = cells.at(1).first()
#assert.eq(first.kind, "compound")
#assert.eq(first.pieces.map(piece => piece.kind), ("value", "glue", "value", "glue"))
#assert.eq(first.pieces.first().value, column-cells(build-spec(data, (format-number("estimate", decimals: 2),), (:))).at(1).first())
#assert.eq(first.real, [#slots-to-content(first.pieces.first().value) (#slots-to-content(first.pieces.at(2).value))])
#assert.eq(slots-to-content(first), first.real)

// A pattern that branches on its values keeps, for the rows the split does not
// describe, exactly what it returned.
#let branching = build-spec(
  data,
  (
    format-number("estimate", decimals: 2),
    format-number("error", decimals: 3),
    columns-combine(
      "effect",
      ("estimate", "error"),
      (value, margin) => if repr(margin).contains("043") [#value] else [#value (#margin)],
    ),
  ),
  (:),
)
#let branched = column-cells(branching).at(1)
#assert.eq(branched.first().kind, "compound")
#assert.eq(type(branched.last()), content)
#holds(branched.last(), "0.57")
#assert(not repr(branched.last()).contains("043"))

// A combine of words has no number to line up, so it stays the pattern's
// content rather than a run of padded boxes.
#let names = column-cells(build-spec(
  (first: ("Ada", "Grace"), last: ("Lovelace", "Hopper")),
  (columns-combine("name", ("first", "last"), (first, last) => [#first #last]),),
  (:),
))
#assert(names.first().all(cell => type(cell) == content))
#holds(names.first().first(), "Ada", "Lovelace")

// A pattern that reads a field its marker does not have cannot be split, and
// with decimal alignment off it is never called with markers at all.
#let fields = (estimate, margin) => [#estimate.text (#margin.text)]
#assert.eq(type(column-cells(build-spec(
  data,
  (format-number("estimate", decimals: 2), format-number("error", decimals: 3), columns-combine("effect", ("estimate", "error"), fields)),
  (:),
)).at(1).first()), dictionary)
#let picky = (estimate, margin) => [#estimate (#float(margin.text))]
#assert.eq(type(column-cells(build-spec(
  data,
  (format-number("estimate", decimals: 2), format-number("error", decimals: 3), columns-combine("effect", ("estimate", "error"), picky)),
  (decimal-align: false),
)).at(1).first()), content)

// With decimal alignment off, a combined cell is the pattern's content.
#let unaligned = column-cells(build-spec(
  data,
  (columns-combine("effect", ("estimate", "error"), (value, margin) => [#value (#margin)]),),
  (decimal-align: false),
))
#assert.eq(type(unaligned.at(1).first()), content)

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

// Where the column goes is resolved once the fold is done, so directive order
// does not decide it. Deciding it mid-fold read whichever columns happened to
// be present at that moment: hiding a source first put the result at the end of
// the table, and hiding it afterwards did not.
#let wide = (a: (1,), b: (2,), c: (3,), d: (4,))
#let joined = (x, y) => [#x/#y]

#let hidden-first = build-spec(wide, (columns-hide("b"), columns-combine("bc", ("b", "c"), joined)), (:))
#let hidden-last = build-spec(wide, (columns-combine("bc", ("b", "c"), joined), columns-hide("b")), (:))
#assert.eq(hidden-first.columns, ("a", "bc", "d"))
#assert.eq(hidden-first.columns, hidden-last.columns)
#assert.eq(hidden-first.hidden, hidden-last.hidden)

// A column hidden twice is hidden once.
#assert.eq(hidden-first.hidden.dedup(), hidden-first.hidden)

// The same holds for a move written either side of the combine that creates the
// column it moves.
#let move-first = build-spec(
  wide,
  (columns-move("bc", before: "a"), columns-combine("bc", ("b", "c"), joined)),
  (:),
)
#let move-last = build-spec(
  wide,
  (columns-combine("bc", ("b", "c"), joined), columns-move("bc", before: "a")),
  (:),
)
#assert.eq(move-first.columns, ("bc", "a", "d"))
#assert.eq(move-first.columns, move-last.columns)

// A source promoted into the stub is no longer a column, and the combined
// column still takes its place rather than falling to the end.
#let stubbed = build-spec(wide, (table-stub(rowname: "b"), columns-combine("bc", ("b", "c"), joined)), (:))
#assert.eq(stubbed.columns, ("a", "bc", "d"))

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
