///! Percentage formatting.

#import "number.typ": format-number

// `scale: 100` suits a proportion; pass `scale: 1` when the values already sit
// on a 0 to 100 range.
#let format-percent(
  columns,
  rows: auto,
  decimals: 1,
  scale: 100,
  symbol: [%],
  space: true,
  ..options
) = format-number(
  columns,
  rows: rows,
  decimals: decimals,
  scale: scale,
  scope: "format-percent",
  suffix: if space { sym.space.nobreak + symbol } else { symbol },
  ..options,
)
