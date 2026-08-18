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
#assert.eq(written(1234.5, 3), "1 230")
#assert.eq(written(0.0012345, 2), "0.0012")
#assert.eq(written(2.5, 2), "2.5")
#assert.eq(written(0.04, 2), "0.040")

// Zero has no significant digit to measure, so the count is the whole of it.
#assert.eq(written(0, 2), "0.00")
