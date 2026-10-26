// Each value of a combined cell sits in a box as wide as the widest rendering
// of that value down the column, and each piece of glue in a box as wide as
// its widest rendering. Every row is then the same run of boxes, so a value or
// a delimiter starts at the same place in every row. What breaks that is a
// piece wider than its box, which pushes everything after it along.

#import "../../lib.typ": columns-combine, format-number, substitute-missing
#import "../../src/format/compound.typ": compound-pieces
#import "../../src/parts/summaries.typ": summary-values
#import "../../src/render/layout.typ": align-cell, column-cells, metrics
#import "../../src/spec.typ": build-spec

#let build(low, high, pattern: (low, high) => [#low, #high], extra: ()) = build-spec(
  (low: low, high: high),
  (
    format-number(("low", "high"), decimals: 2),
    ..extra,
    columns-combine("interval", ("low", "high"), pattern),
  ),
  (:),
)

// Every piece fits its box, under the text style its cell renders in.
#let fits(spec, text-style: (part, row, name) => none) = {
  let cells = column-cells(spec).first()
  let metric = metrics(spec, (cells,), summary-values(spec), text-style: text-style).first()
  assert.eq(metric.kind, "compound")
  for (row, cell) in cells.enumerate() {
    let style = text-style("body", row, "interval")
    let in-style(body) = measure(if style == none { body } else { text(..style, body) }).width
    let pieces = compound-pieces(cell, metric)
    for (position, piece) in cell.pieces.enumerate() {
      let measures = metric.pieces.at(position)
      let where = "row " + str(row) + " piece " + str(position)
      // A padded number is a run of fixed boxes, so what can overflow is a
      // fragment inside one: each is measured bare, in the cell's style and the
      // pattern's wrapper, against the box it sits in.
      if piece.kind == "value" and type(piece.value) == dictionary {
        let dressed(body) = if piece.wrapper == none { body } else {
          show metadata.where(value: (keisen-value: piece.index)): _ => body
          piece.wrapper
        }
        for slot in ("integer", "fraction") {
          assert(
            in-style(dressed[#piece.value.at(slot)]) <= measures.number.at(slot),
            message: where + " " + slot + " overflows its box",
          )
        }
      } else {
        assert(in-style(pieces.at(position)) <= measures.width, message: where + " overflows its box")
      }
    }
  }
  let widths = cells.map(cell => measure(align-cell(cell, metric)).width)
  assert(widths.all(width => width == widths.first()), message: "every row must be the same run of boxes")
}

#let bounds = build((-0.61, 0.07, -0.02), (-0.23, 0.29, 0.44))

#context fits(bounds)

// A bold row renders wider digits, and the boxes are measured for them.
#context fits(bounds, text-style: (part, row, name) => if row == 1 { (weight: "bold") } else { none })

// A value wrapped in `strong` by the pattern is measured bold.
#context fits(build((-0.61, 1111.07), (-0.23, 0.29), pattern: (low, high) => [#strong(low), #high]))

// A missing bound is opaque inside its own box, and the rest of the row still
// lines up; a long replacement widens that box rather than spilling over.
#context fits(build(
  (-0.61, none, -0.02),
  (-0.23, 0.29, 0.44),
  extra: (substitute-missing("low", replacement: [not estimable]),),
))

// A row the split does not describe is the pattern's own content.
#let branching = build(
  (-0.61, 0.07),
  (-0.23, 0.29),
  pattern: (low, high) => if repr(low).contains("07") [#high] else [#low, #high],
)
#context {
  let cells = column-cells(branching).first()
  let metric = metrics(branching, (cells,), summary-values(branching)).first()
  assert.eq(align-cell(cells.last(), metric), cells.last())
}

// Glue keeps its spaces: a space at the edge of a box is otherwise dropped,
// and `#low (#high)` would render as `low(high)`.
#context {
  let spec = build((-0.61, 0.07), (-0.23, 0.29), pattern: (low, high) => [#low (#high)])
  let cells = column-cells(spec).first()
  let metric = metrics(spec, (cells,), summary-values(spec)).first()
  let glue = compound-pieces(cells.first(), metric).at(1)
  assert(measure(box(glue)).width > measure([(]).width, message: "the space before the bracket is kept")
}
