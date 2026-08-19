// A decimal count that is not a count reached the rounding arithmetic and died
// as a raw Typst error, in a grammar the caller never wrote. It is pre-checked
// instead, because Typst has no way to recover from the panic.
// expect: format-number: decimals must be an integer or auto
// expect: got none

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (ratio: (1.2345,)),
  format-number("ratio", decimals: none),
)
