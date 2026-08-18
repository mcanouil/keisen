///! Number formatting over decimal arithmetic.
///!
///! Every scaling and rounding step happens in Typst's `decimal` type, which is
///! fixed-point with 28 to 29 significant digits, so 0.145 at two decimals is
///! not at the mercy of binary representation. Floats reach it through their
///! shortest round-trip string, since `decimal(3.14)` is documented as
///! imprecise and warns.

#import "../utils/errors.typ": check, fail, fail-enum

// A decimal holds 28 to 29 significant digits and raises rather than saturating
// on overflow, so both ends of the range are checked before construction: too
// large to represent, and too small to represent without more fractional digits
// than it has. Typst has no try, so neither can be attempted and recovered.
#let _limit = 7.9e28

#let _numeric = regex("^[+-]?\d+(\.\d+)?$")

// Digits a decimal literal would need, counting the fractional ones that a
// leading run of zeroes pushes beyond the scale.
#let _fits(text) = {
  let parts = text.trim("-", at: start).trim("+", at: start).split(".")
  let integer = parts.first().trim("0", at: start)
  let fraction = if parts.len() > 1 { parts.at(1) } else { "" }
  integer.len() + fraction.len() <= 28
}

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
    if not _fits(text) { return none }
    return decimal(text)
  }
  if kind == str {
    if value.match(_numeric) == none { return none }
    if not _fits(value) { return none }
    return decimal(value)
  }
  none
}

// `digits` may be negative, which rounds to tens, hundreds, and so on; that is
// how significant-digit formatting reaches the integer part.
#let round-decimal(value, digits, mode) = {
  if mode not in ("half-up", "half-even") {
    fail-enum("format-number", "rounding", mode, ("half-up", "half-even"))
  }
  if mode == "half-up" { return calc.round(value, digits: digits) }

  let scale = calc.pow(decimal(10), calc.abs(digits))
  let shifted = if digits < 0 { value / scale } else { value * scale }

  // The tie test runs through calc.trunc, which returns an int, so a shifted
  // value beyond the integer range takes plain rounding instead. Nothing that
  // large can sit on a tie: it has no fractional part left to sit on.
  if calc.abs(shifted) >= decimal("9223372036854775807") {
    return calc.round(value, digits: digits)
  }

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

// A size of `none` or anything below one means no grouping; a size of zero
// would otherwise never shorten the remainder and loop forever.
#let group-digits(digits, size, separator) = {
  if size == none or size < 1 or digits.len() <= size { return digits }
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
#let _places-for-significant(number, count) = {
  let digits = str(calc.abs(number)).split(".")
  let integer = digits.first().trim("0", at: start)
  if integer != "" { return count - integer.len() }
  let fraction = if digits.len() > 1 { digits.at(1) } else { "" }
  // Zero has no significant digit to place, and the arithmetic below would read
  // its scale as leading zeros instead: `decimal("0.00")` writes two of them, so
  // a zero from a string counted four places where a zero from an integer
  // counted two. A decimal keeps the scale it was written with, and rounding
  // does not always keep it, so the scale must not reach the count at all.
  if fraction.trim("0") == "" { return count }
  let leading = fraction.len() - fraction.trim("0", at: start).len()
  leading + count
}

// The same, measured against the value that is printed rather than the value
// that arrived. Rounding carries into a new integer digit, and the place was
// read off the magnitude before it: 9.99 at two significant digits rounded to
// 10.0 and kept the place computed for a one-digit integer, printing three
// digits where two were asked for.
//
// One further measurement settles it. Rounding to the wider place shows the
// magnitude the number prints at, and rounding the original to the narrower
// place reaches the same magnitude, so a third pass reads what the second did.
#let _decimals-for-significant(number, count, mode) = {
  let places = _places-for-significant(number, count)
  _places-for-significant(round-decimal(number, places, mode), count)
}

// An infinity written as whatever the caller said to write, or `none` when they
// said nothing. Alignment sees opaque content: an infinity has no digits to pad
// a column against.
#let unbounded(value, options) = {
  let written = options.at("infinity", default: none)
  if written == none or value not in (float.inf, -float.inf) { return none }
  if value == -float.inf { [-] + written } else { written }
}

#let format-value(value, options) = {
  // Every formatter in the family lands here, so the scope travels with the
  // options: a currency column that holds a word should say so as
  // format-currency rather than as something the caller never wrote.
  let scope = options.at("scope", default: "format-number")
  let number = to-decimal(value)
  if number == none {
    let written = unbounded(value, options)
    if written != none { return written }
    fail(
      scope,
      "value is not a finite number",
      value: value,
      hint: "Only finite numbers are formatted here; use format() for anything else.",
    )
  }

  if options.scale != 1 { number = number * decimal(str(options.scale)) }

  let decimals = if options.at("significant", default: none) != none {
    _decimals-for-significant(number, options.significant, options.rounding)
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
    prefix: options.at("prefix", default: none),
    integer: group-digits(integer, options.grouping, options.group-separator),
    separator: if shown > 0 { options.decimal-separator } else { "" },
    fraction: fraction,
    exponent: options.at("exponent", default: none),
    suffix: options.at("suffix", default: none),
  )
}

// `columns` is a required positional argument throughout the format family:
// Typst positional parameters cannot carry defaults, so "every column" is
// written explicitly as `auto`.
#let format(columns, function, rows: auto, scope: "format") = (
  kind: "format",
  columns: columns,
  rows: rows,
  function: function,
  cell: false,
  // The name the caller wrote, so a directive naming a column the table does
  // not have reports under `format-date` rather than under `format`.
  scope: scope,
)

// A directive whose separators or rounding may be `auto`, meaning the theme
// decides.
//
// The theme is not resolved until render time, so such a directive carries how
// to build its formatter rather than the formatter itself: `build` takes the
// theme's number conventions and returns the `value => slots` closure. This is
// the same shape a nanoplot uses to reach the column it is drawn against.
//
// `function` is none deliberately. Every path that formats a cell resolves the
// directive through `formatter-for` in src/format/apply.typ, and one that
// forgot would rather fail than quietly pick a separator nobody asked for.
#let format-family(columns, build, rows: auto, scope: "format-number") = (
  kind: "format",
  columns: columns,
  rows: rows,
  function: none,
  family: build,
  cell: false,
  scope: scope,
)

// The one formatter that reads the row rather than the value, for a cell whose
// content depends on its neighbours. The row it receives is the input row, so
// hidden columns and the reserved `_index` key are both reachable.
//
// `columns-combine` covers the common case of building one cell from named
// neighbours, and reads better where it fits; this is the general form.
//
// A summary row is an aggregate of a column and has no row behind it, so a cell
// formatter covers no column: see `covering` in src/render/layout.typ.
#let format-cell(columns, function, rows: auto) = (
  kind: "format",
  columns: columns,
  rows: rows,
  function: function,
  cell: true,
  scope: "format-cell",
)

#let format-number(
  columns,
  rows: auto,
  decimals: 2,
  significant: none,
  grouping: 3,
  // `auto` means the theme decides, through number-group-separator and
  // number-decimal-separator, so a convention is set once for the table.
  group-separator: auto,
  decimal-separator: auto,
  scale: 1,
  sign: false,
  // `auto` means the theme decides, through number-rounding.
  rounding: auto,
  negative-zero: false,
  prefix: none,
  suffix: none,
  exponent: none,
  infinity: none,
  // Named by whichever formatter in the family called, so a failure reports the
  // function the caller actually wrote.
  scope: "format-number",
) = format-family(
  columns,
  conventions => value => format-value(
    value,
    (
      scope: scope,
      prefix: prefix,
      suffix: suffix,
      exponent: exponent,
      infinity: infinity,
      decimals: decimals,
      significant: significant,
      grouping: grouping,
      group-separator: if group-separator == auto { conventions.group } else { group-separator },
      decimal-separator: if decimal-separator == auto { conventions.decimal } else { decimal-separator },
      scale: scale,
      sign: sign,
      rounding: if rounding == auto { conventions.rounding } else { rounding },
      negative-zero: negative-zero,
    ),
  ),
  rows: rows,
  scope: scope,
)

// Forwarded options come after `decimals`, and a later named argument wins, so
// a decimal count is refused rather than quietly turning integers into
// fractions.
#let format-integer(columns, rows: auto, ..options) = {
  let named = options.named()
  check(
    "decimals" not in named and "significant" not in named,
    "format-integer",
    "decimals and significant do not apply to integers",
    hint: "Use format-number when a fractional part is wanted.",
  )
  format-number(columns, rows: rows, decimals: 0, scope: "format-integer", ..options)
}
