// A column's decimal metrics are the widest rendering of each slot. A cell
// whose style changes the text, such as a bold row, renders its digits wider,
// so the metrics must be measured in that cell's style or its separator moves.

#import "../../src/format/align.typ": column-metrics

#let slots = (
  kind: "number",
  sign: "",
  prefix: none,
  integer: "1 111",
  separator: ".",
  fraction: "11",
  exponent: none,
  suffix: none,
)

#context {
  let plain = column-metrics((slots, slots))
  let styled = column-metrics((slots, slots), styles: (none, (weight: "bold")))
  assert(styled.integer > plain.integer, message: "a bold row must widen the integer slot")
  assert.eq(styled.integer, measure(text(weight: "bold", slots.integer)).width)
  assert.eq(styled.fraction, measure(text(weight: "bold", slots.fraction)).width)
}

// No style at all measures exactly as before.
#context {
  assert.eq(column-metrics((slots,), styles: (none,)), column-metrics((slots,)))
}

// A style belongs to its own cell: an opaque cell before the number does not
// shift which style the number is measured in.
#context {
  let styled = column-metrics(([Alpha], slots), styles: ((weight: "bold"), none))
  assert.eq(styled, column-metrics((slots,)))
}

// --- the renderer's metrics read each cell's style ---
//
// Body cells are addressed by data row, group summaries by `(group, row)`, and
// grand summaries by their index, as `assemble` addresses them in `style-for`.

#import "../../lib.typ": aggregate-sum, format-number, grand-summary-rows
#import "../../src/parts/summaries.typ": summary-values
#import "../../src/render/layout.typ": column-cells, metrics
#import "../../src/spec.typ": build-spec

#let spec = build-spec(
  (x: (1111.11, 1111.11)),
  (format-number("x", decimals: 2), grand-summary-rows(functions: ("Total": aggregate-sum))),
  (:),
)

#context {
  let cells = column-cells(spec)
  let summaries = summary-values(spec)
  let plain = metrics(spec, cells, summaries).first()
  let body = metrics(
    spec,
    cells,
    summaries,
    text-style: (part, row, name) => if part == "body" and row == 1 { (weight: "bold") } else { none },
  ).first()
  assert.eq(body.integer, measure(text(weight: "bold", cells.first().first().integer)).width)

  let grand = metrics(
    spec,
    cells,
    summaries,
    text-style: (part, row, name) => if part == "grand-summary" and row == 0 { (size: 2em) } else { none },
  ).first()
  assert(grand.integer > body.integer, message: "a styled grand summary must widen the column")
  assert(plain.integer < body.integer)
}
