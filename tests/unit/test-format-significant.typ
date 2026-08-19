// Significant-digit formatting resolves the count to a rounding place, and the
// place was measured against the value before it was rounded. A value that
// carried into a new integer digit kept the place computed for the old one, so
// 9.99 to two significant digits printed 10.0: three digits where two were
// asked for, claiming a precision the value does not have.

#import "../../src/format/number.typ": format-value

#let options = (
  decimals: 2,
  significant: none,
  grouping: 3,
  group-separator: " ",
  decimal-separator: ".",
  scale: 1,
  sign: false,
  rounding: "half-up",
  negative-zero: false,
)

#let written(value, count) = {
  let slots = format-value(value, (..options, significant: count))
  slots.integer + slots.separator + slots.fraction
}

#let written-half-even(value, count) = {
  let slots = format-value(value, (..options, significant: count, rounding: "half-even"))
  slots.integer + slots.separator + slots.fraction
}

// The carrying cases. R writes `signif(9.99, 2)` as 10 and Python writes
// `"%.2g" % 9.99` as 10, which is what two significant digits of 9.99 are.
#assert.eq(written(9.99, 2), "10")
#assert.eq(written(0.0999, 2), "0.10")
#assert.eq(written(0.00996, 2), "0.010")
#assert.eq(written(0.99999, 2), "1.0")
#assert.eq(written(9.99999, 3), "10.0")

// The sign is read from the value that entered rounding, so it survives a carry.
#assert.eq(format-value(-9.99, (..options, significant: 2)).sign, "-")
#assert.eq(written(-9.99, 2), "10")

// Values that do not carry are unchanged, and so are the ones that carry into
// an integer with no fractional part to trim: trailing integer zeros cannot be
// dropped without scientific notation, so 99.9 to two significant digits is 100
// and 123.4 is 120, both already right.
#assert.eq(written(99.9, 2), "100")
#assert.eq(written(123.4, 2), "120")
#assert.eq(written(2.5, 2), "2.5")
#assert.eq(written(0.04, 2), "0.040")

// The place is measured against the rounded value, so it is measured under the
// rounding the caller asked for. Both modes carry here, and both must print the
// digits that were asked for.
#assert.eq(written-half-even(9.99, 2), "10")
#assert.eq(written-half-even(0.0999, 2), "0.10")

// A string and a decimal carry the scale they were written with, and `str`
// prints it: `decimal("0.00")` writes two trailing zeros where the integer 0
// writes none. The scale is not a significant digit, so it must not reach the
// count. It did, and a zero from a string printed four decimals under half-up
// and two under half-even: one value, two answers, neither asked for.
#assert.eq(written("0.00", 2), "0.00")
#assert.eq(written-half-even("0.00", 2), "0.00")
#assert.eq(written(0, 2), "0.00")
#assert.eq(written-half-even(0, 2), "0.00")

// The same scale on a value that is not zero is read as the precision it is.
#assert.eq(written("9.990", 2), "10")
#assert.eq(written("0.04000", 2), "0.040")

// --- significant alone, through the directives that reach it ---
//
// `decimals` and `significant` are mutually exclusive, and refusing both
// together must not refuse either alone. `format-percent` and `format-currency`
// each carry their own decimal count and forward `significant` through their
// options sink, so a count they never resolved is the case that breaks.

#import "../../lib.typ": format-currency, format-number, format-percent
#import "../../src/format/apply.typ": apply-formats

#let slots(directive, column, value) = {
  let row = (_index: 0)
  row.insert(column, value)
  apply-formats((row,), (directive,), column).first()
}

#let printed(directive, column, value) = {
  let cell = slots(directive, column, value)
  cell.integer + cell.separator + cell.fraction
}

#assert.eq(printed(format-number("ratio", significant: 2), "ratio", 1.2345), "1.2")
#assert.eq(printed(format-number("ratio", decimals: 3), "ratio", 1.2345), "1.235")

// Two significant digits of 18.234 per cent are 18, which the one decimal the
// formatter defaults to would print as 18.2, so the count reaches the value
// rather than being dropped on the way.
#assert.eq(printed(format-percent("share", significant: 2), "share", 0.18234), "18")

// A currency resolves 0 or 2 places from the currency, and neither reaches a
// caller who asked for significant digits instead.
#assert.eq(printed(format-currency("amount", significant: 3), "amount", 1234.5), "1" + sym.space.thin + "230")
#assert.eq(printed(format-currency("amount", currency: "JPY", significant: 2), "amount", 1234.5), "1" + sym.space.thin + "200")

// --- a key that asks for nothing is not a refusal ---
//
// `auto` and `none` are how the family says "no opinion", so a wrapper that
// forwards a fixed set of keys reaches format-integer as it reaches the rest.

#import "../../lib.typ": format-integer

#assert.eq(
  printed(format-integer("count", decimals: auto, significant: none), "count", 1234.5),
  "1" + sym.space.thin + "235",
)

// --- the ends of both ranges are inside them ---
//
// A count is refused outside 1 to 28, and a place outside -28 to 28. The bounds
// themselves are accepted, so an off-by-one that narrows either range fails
// here rather than in a document.

#assert.eq(printed(format-number("ratio", significant: 1), "ratio", 1.2345), "1")
// One digit before the point, so 28 significant digits leave 27 after it.
#assert.eq(printed(format-number("ratio", significant: 28), "ratio", 1.5).len(), 29)
#assert.eq(printed(format-number("ratio", decimals: 28), "ratio", 1.5).len(), 30)
#assert.eq(printed(format-number("ratio", decimals: -28), "ratio", 1.5), "0")

// The defaults each formatter carries are unchanged by the refusal.
#assert.eq(printed(format-number("ratio"), "ratio", 1.2345), "1.23")
#assert.eq(printed(format-percent("share"), "share", 0.18234), "18.2")
#assert.eq(printed(format-currency("amount"), "amount", 1234.5), "1" + sym.space.thin + "234.50")
#assert.eq(printed(format-currency("amount", currency: "JPY"), "amount", 1234.5), "1" + sym.space.thin + "235")
