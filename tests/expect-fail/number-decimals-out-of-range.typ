// A decimal holds 28 places, so a larger count writes zeros the value never
// carried: 500 of them in every cell of the column.
// expect: format-number: decimals must be between -28 and 28
// expect: got 500.
// expect: A decimal holds 28 places; a count outside them writes digits the value does not carry.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (ratio: (1.5,)),
  format-number("ratio", decimals: 500),
)
