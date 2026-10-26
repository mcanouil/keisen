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
