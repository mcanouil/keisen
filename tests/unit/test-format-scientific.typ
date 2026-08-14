// Scientific notation fills the exponent slot, which the alignment stage
// reserved from the start and never rendered until something wrote to it.

#import "../../lib.typ": format-scientific
#import "../../src/format/apply.typ": apply-formats

#let slots(directive, value) = apply-formats(((size: value, _index: 0),), (directive,), "size").first()

// The exponent as the formatter renders it, so these assert which power a value
// sits on rather than how the superscript happens to be nested.
#let power(exponent) = [#h(0.15em)#sym.times#h(0.15em)10#super[#exponent]]
#let e-form(exponent) = [e#exponent]

#let large = slots(format-scientific("size"), 12345)
#assert.eq(large.integer, "1")
#assert.eq(large.fraction, "23")
#assert.eq(large.exponent, power(4))

// The mantissa is computed by shifting the decimal point rather than by
// dividing through a float, so the digits are the ones the value had.
#assert.eq(slots(format-scientific("size", decimals: 4), 12345).fraction, "2345")

#let small = slots(format-scientific("size"), 0.00123)
#assert.eq(small.integer, "1")
#assert.eq(small.fraction, "23")
#assert.eq(small.exponent, power(-3))

// Zero has no exponent to speak of, and 0 × 10⁰ is how it is said.
#let zero = slots(format-scientific("size"), 0)
#assert.eq(zero.integer, "0")
#assert.eq(zero.exponent, power(0))

#let negative = slots(format-scientific("size"), -4500)
#assert.eq(negative.sign, "-")
#assert.eq(negative.integer, "4")
#assert.eq(negative.fraction, "50")
#assert.eq(negative.exponent, power(3))

// A value already at one digit keeps its exponent rather than losing it.
#assert.eq(slots(format-scientific("size"), 7).exponent, power(0))

// The e form, for people who read output rather than typeset it.
#assert.eq(slots(format-scientific("size", exponent: "e"), 12345).exponent, e-form(4))
#assert.eq(slots(format-scientific("size", exponent: "e"), 0.00123).exponent, e-form(-3))

// A magnitude beyond what `decimal` can hold is exactly what scientific
// notation is for, so it is formatted rather than refused.
#let huge = slots(format-scientific("size"), 1.5e40)
#assert.eq(huge.integer, "1")
#assert.eq(huge.fraction, "50")
#assert.eq(huge.exponent, power(40))

#let tiny = slots(format-scientific("size"), 2.5e-40)
#assert.eq(tiny.integer, "2")
#assert.eq(tiny.exponent, power(-40))

// Rounding that carries into the next power moves the exponent with it, or
// 9.99 rounds to 10.0 × 10³ and stops being scientific notation.
#let carried = slots(format-scientific("size", decimals: 1), 9990)
#assert.eq(carried.integer, "1")
#assert.eq(carried.fraction, "0")
#assert.eq(carried.exponent, power(4))
