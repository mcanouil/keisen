///! Number formatting over decimal arithmetic.
///!
///! Every scaling and rounding step happens in Typst's `decimal` type, which is
///! fixed-point with 28 to 29 significant digits, so 0.145 at two decimals is
///! not at the mercy of binary representation. Floats reach it through their
///! shortest round-trip string, since `decimal(3.14)` is documented as
///! imprecise and warns.

#import "../utils/errors.typ": fail

// Beyond this magnitude a decimal construction would overflow, and a decimal
// overflow raises rather than saturating, so the check happens first.
#let _limit = 7.9e28

#let _numeric = regex("^[+-]?\d+(\.\d+)?$")

#let to-decimal(value) = {
  let kind = type(value)
  if kind == decimal { return value }
  if kind == int { return decimal(value) }
  if kind == float {
    // NaN is the only value that differs from itself.
    if value != value { return none }
    if value == float.inf or value == -float.inf { return none }
    if calc.abs(value) >= _limit { return none }
    let text = str(value)
    // Exponent forms are the scientific formatter's business, not this one's.
    if "e" in text or "E" in text { return none }
    return decimal(text)
  }
  if kind == str {
    if value.match(_numeric) == none { return none }
    return decimal(value)
  }
  none
}

// `digits` may be negative, which rounds to tens, hundreds, and so on; that is
// how significant-digit formatting reaches the integer part.
#let round-decimal(value, digits, mode) = {
  if mode == "half-up" { return calc.round(value, digits: digits) }

  let scale = calc.pow(decimal(10), calc.abs(digits))
  let shifted = if digits < 0 { value / scale } else { value * scale }
  let truncated = calc.trunc(shifted)
  let remainder = shifted - decimal(truncated)

  let rounded = if remainder == decimal("0.5") {
    if calc.rem(truncated, 2) == 0 { truncated } else { truncated + 1 }
  } else if remainder == decimal("-0.5") {
    if calc.rem(truncated, 2) == 0 { truncated } else { truncated - 1 }
  } else {
    calc.round(shifted, digits: 0)
  }

  if digits < 0 { decimal(rounded) * scale } else { decimal(rounded) / scale }
}

#let group-digits(digits, size, separator) = {
  if size == none or digits.len() <= size { return digits }
  let blocks = ()
  let rest = digits
  while rest.len() > size {
    blocks.push(rest.slice(rest.len() - size))
    rest = rest.slice(0, rest.len() - size)
  }
  blocks.push(rest)
  blocks.rev().join(separator)
}

// Decimal places that leave `count` significant digits in `number`.
#let _decimals-for-significant(number, count) = {
  let digits = str(calc.abs(number)).split(".")
  let integer = digits.first().trim("0", at: start)
  if integer != "" { return count - integer.len() }
  let fraction = if digits.len() > 1 { digits.at(1) } else { "" }
  let leading = fraction.len() - fraction.trim("0", at: start).len()
  leading + count
}

#let format-value(value, options) = {
  let number = to-decimal(value)
  if number == none {
    fail(
      "format-number",
      "value is not a finite number",
      value: value,
      hint: "Use substitute-missing for gaps, or format() for anything else.",
    )
  }

  if options.scale != 1 { number = number * decimal(str(options.scale)) }

  let decimals = if options.at("significant", default: none) != none {
    _decimals-for-significant(number, options.significant)
  } else {
    options.decimals
  }

  // Rounding -0.4 to zero drops the sign, so negativity is read from the value
  // that entered rounding rather than from the digits that came out.
  let negative = number < decimal(0)

  // `str(decimal)` writes U+2212 MINUS SIGN rather than an ASCII hyphen, so the
  // sign is removed by taking the magnitude instead of by slicing the string.
  let text = str(calc.abs(round-decimal(number, decimals, options.rounding)))

  // Negative rounding places round the integer part, so nothing is shown after
  // the separator and the padding below works on a non-negative count.
  let shown = calc.max(0, decimals)

  let parts = text.split(".")
  let integer = parts.first()
  let fraction = if parts.len() > 1 { parts.at(1) } else { "" }
  if fraction.len() > shown { fraction = fraction.slice(0, shown) }
  while fraction.len() < shown { fraction = fraction + "0" }

  // Significant-digit rounding zeroes trailing integer digits rather than
  // dropping them, which `str` already reflects.
  let zero = integer.trim("0") == "" and fraction.trim("0") == ""
  let sign = if negative and (not zero or options.negative-zero) {
    "-"
  } else if options.sign and not negative and not zero {
    "+"
  } else {
    ""
  }

  (
    kind: "number",
    sign: sign,
    prefix: none,
    integer: group-digits(integer, options.grouping, options.group-separator),
    separator: if shown > 0 { options.decimal-separator } else { "" },
    fraction: fraction,
    exponent: none,
    suffix: none,
  )
}

// `columns` is a required positional argument throughout the format family:
// Typst positional parameters cannot carry defaults, so "every column" is
// written explicitly as `auto`.
#let format(columns, function, rows: auto) = (
  kind: "format",
  columns: columns,
  rows: rows,
  function: function,
)

#let format-number(
  columns,
  rows: auto,
  decimals: 2,
  significant: none,
  grouping: 3,
  group-separator: sym.space.thin,
  decimal-separator: ".",
  scale: 1,
  sign: false,
  rounding: "half-up",
  negative-zero: false,
) = format(
  columns,
  value => format-value(
    value,
    (
      decimals: decimals,
      significant: significant,
      grouping: grouping,
      group-separator: group-separator,
      decimal-separator: decimal-separator,
      scale: scale,
      sign: sign,
      rounding: rounding,
      negative-zero: negative-zero,
    ),
  ),
  rows: rows,
)

#let format-integer(columns, rows: auto, ..options) = format-number(
  columns,
  rows: rows,
  decimals: 0,
  ..options,
)
