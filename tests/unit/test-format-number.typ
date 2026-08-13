// Numeric formatting: decimal arithmetic, rounding modes, digit grouping,
// and the seven alignment slots.

#import "../../src/format/number.typ": to-decimal, round-decimal, group-digits, format-value

// --- value to decimal ---

#assert.eq(to-decimal(2), decimal("2"))
#assert.eq(to-decimal("3.140"), decimal("3.140"))
#assert.eq(to-decimal(0.1), decimal("0.1"))
#assert.eq(to-decimal(decimal("1.5")), decimal("1.5"))
#assert.eq(to-decimal(float.nan), none)
#assert.eq(to-decimal(float.inf), none)
#assert.eq(to-decimal(1e30), none)
#assert.eq(to-decimal("not a number"), none)
#assert.eq(to-decimal(none), none)

// --- rounding ---

#assert.eq(round-decimal(decimal("2.5"), 0, "half-up"), decimal("3"))
#assert.eq(round-decimal(decimal("-2.5"), 0, "half-up"), decimal("-3"))
#assert.eq(round-decimal(decimal("2.5"), 0, "half-even"), decimal("2"))
#assert.eq(round-decimal(decimal("3.5"), 0, "half-even"), decimal("4"))
#assert.eq(round-decimal(decimal("-2.5"), 0, "half-even"), decimal("-2"))
#assert.eq(round-decimal(decimal("2.4"), 0, "half-even"), decimal("2"))
#assert.eq(round-decimal(decimal("0.145"), 2, "half-up"), decimal("0.15"))

// --- digit grouping ---

#assert.eq(group-digits("1234567", 3, " "), "1 234 567")
#assert.eq(group-digits("1234", 3, " "), "1 234")
#assert.eq(group-digits("123", 3, " "), "123")
#assert.eq(group-digits("12", 3, " "), "12")
#assert.eq(group-digits("1234", none, " "), "1234")

// --- alignment slots ---

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

#let slots = format-value(1234.5, options)
#assert.eq(slots.kind, "number")
#assert.eq(slots.sign, "")
#assert.eq(slots.integer, "1 234")
#assert.eq(slots.separator, ".")
#assert.eq(slots.fraction, "50")

// Integers keep an empty fraction, and the separator slot stays empty with it.
#let integers = format-value(42, (..options, decimals: 0))
#assert.eq(integers.integer, "42")
#assert.eq(integers.separator, "")
#assert.eq(integers.fraction, "")

// A negative rounding to zero loses its sign.
#let negative-zero = format-value(-0.4, (..options, decimals: 0))
#assert.eq(negative-zero.sign, "")
#assert.eq(negative-zero.integer, "0")

// ... unless asked to keep it.
#let kept = format-value(-0.4, (..options, decimals: 0, negative-zero: true))
#assert.eq(kept.sign, "-")

// Negatives that survive rounding keep their sign, and an explicit sign shows.
#assert.eq(format-value(-12.5, options).sign, "-")
#assert.eq(format-value(-12.5, options).integer, "12")
#assert.eq(format-value(12.5, (..options, sign: true)).sign, "+")

// Scaling happens before rounding.
#assert.eq(format-value(0.1234, (..options, scale: 100, decimals: 1)).fraction, "3")

// Significant digits replace a decimal count.
#assert.eq(format-value(1234.5, (..options, significant: 3)).integer, "1 230")
#assert.eq(format-value(0.0012345, (..options, significant: 2)).fraction, "0012")

// Strings carry their own precision, so trailing zeroes survive.
#assert.eq(format-value("2.500", (..options, decimals: 3)).fraction, "500")
