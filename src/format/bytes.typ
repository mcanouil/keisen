///! Byte sizes.
///!
///! The unit is chosen so the number stays readable, and it says which
///! convention it counted in: 1 kB is a thousand bytes and 1 KiB is 1024, and a
///! table that does not say which it means is telling the reader nothing.

#import "../utils/errors.typ": fail-enum
#import "number.typ": format, format-value, to-decimal

#let _UNITS = (
  "1024": ([B], [KiB], [MiB], [GiB], [TiB], [PiB]),
  "1000": ([B], [kB], [MB], [GB], [TB], [PB]),
)

#let _slots(value, options) = {
  let number = to-decimal(value)
  // Not a number: format-value reports it in the grammar the rest of the family
  // uses, naming this formatter.
  if number == none { return format-value(value, options) }

  let step = decimal(str(options.base))
  let units = _UNITS.at(str(options.base))

  // The largest unit the magnitude reaches. Past the last one the number grows
  // instead, since inventing a prefix nobody reads helps nobody.
  let magnitude = calc.abs(number)
  let scaled = magnitude
  let index = 0
  while scaled >= step and index < units.len() - 1 {
    scaled = scaled / step
    index += 1
  }

  format-value(
    if number < decimal(0) { -scaled } else { scaled },
    options
      + (
        // Whole bytes: a fractional byte is not a quantity anyone has.
        decimals: if index == 0 { 0 } else { options.decimals },
        suffix: sym.space.nobreak + units.at(index),
      ),
  )
}

#let format-bytes(
  columns,
  rows: auto,
  base: 1024,
  decimals: 1,
  grouping: 3,
  group-separator: sym.space.thin,
  decimal-separator: ".",
  sign: false,
  rounding: "half-up",
) = {
  if base not in (1000, 1024) {
    fail-enum("format-bytes", "base", base, ("1000", "1024"))
  }

  format(
    columns,
    rows: rows,
    value => _slots(value, (
      scope: "format-bytes",
      base: base,
      prefix: none,
      suffix: none,
      exponent: none,
      decimals: decimals,
      significant: none,
      grouping: grouping,
      group-separator: group-separator,
      decimal-separator: decimal-separator,
      scale: 1,
      sign: sign,
      rounding: rounding,
      negative-zero: false,
    )),
  )
}
