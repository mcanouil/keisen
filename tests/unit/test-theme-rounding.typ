// A number directive with `rounding: auto` takes the theme's number-rounding,
// exactly as `group-separator` and `decimal-separator` already do. Rounding is a
// convention of the document rather than of one column, so a table sets it once
// instead of on every directive.

#import "../../src/data.typ": normalise
#import "../../src/format/apply.typ": apply-formats
#import "../../src/format/number.typ": format-number

#let rows = normalise((value: (0.125, 0.135)))

// A built-in formatter returns the alignment slots rather than content, so the
// digits are read back from the slots the column would have been padded to.
#let digits(slots) = slots.integer + slots.separator + slots.fraction

#let formatted(options, ..directive) = apply-formats(
  rows,
  (format-number("value", decimals: 2, ..directive),),
  "value",
  options: options,
).map(digits)

// Half-up is the default, and rounds a tie away from zero.
#assert.eq(formatted((:)), ("0.13", "0.14"))

// Half-even rounds a tie to the even digit, so the first goes down.
#assert.eq(formatted(("number-rounding": "half-even")), ("0.12", "0.14"))

// A directive naming its own mode is not overruled by the theme.
#assert.eq(
  formatted(("number-rounding": "half-even"), rounding: "half-up"),
  ("0.13", "0.14"),
)
