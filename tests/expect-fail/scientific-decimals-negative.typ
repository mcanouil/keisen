// A negative count rounds to a place above the point, which format-number
// offers and a mantissa cannot use: one digit sits before the point, so
// rounding it away prints 0 × 10⁻⁴ for every value in the column.
// expect: format-scientific: decimals must be between 0 and 28
// expect: got -1.
// expect: A decimal holds 28 places; a count outside them writes digits the value does not carry.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (mass: (0.000123,)),
  format-scientific("mass", decimals: -1),
)
