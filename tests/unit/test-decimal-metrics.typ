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

// --- the sign and prefix sit against the digits ---
//
// A sign belongs to its number, so it moves with the integer rather than
// keeping a slot of its own: in a column of −0.42 and 120.50 the sign sits
// beside the 0, and the column is no wider than its widest number.

#import "../../src/format/align.typ": align-slots

#let number(sign, prefix, integer, fraction) = (
  kind: "number",
  sign: sign,
  prefix: prefix,
  integer: integer,
  separator: ".",
  fraction: fraction,
  exponent: none,
  suffix: none,
)

// Kerning across a box edge is lost, so the boxed run can differ from the
// same text set in one piece by a fraction of a point.
#let close(got, expected) = assert(
  calc.abs((got - expected).pt()) < 0.1,
  message: "aligned width " + repr(got) + ", widest number " + repr(expected),
)

#let whole(value) = (
  [#(value.sign)] + (if value.prefix == none { [] } else { value.prefix }) + [#(value.integer)#(value.separator)#(value.fraction)]
)

#context {
  let column = (number("−", none, "0", "42"), number("", none, "120", "50"))
  let metrics = column-metrics(column)
  let widest = calc.max(..column.map(value => measure(whole(value)).width))
  for value in column {
    close(measure(align-slots(value, metrics)).width, widest)
  }
}

#context {
  let column = (number("", "US$", "5", "00"), number("−", none, "1000", "00"))
  let metrics = column-metrics(column)
  let widest = calc.max(..column.map(value => measure(whole(value)).width))
  for value in column {
    close(measure(align-slots(value, metrics)).width, widest)
  }
}
