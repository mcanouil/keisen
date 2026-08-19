// Zero significant digits keep none of the value: the place arithmetic rounds
// 1234.5 to the ten thousands and prints 0, which is a column of nothing rather
// than a column of rounded numbers.
// expect: format-number: significant must be between 1 and 28
// expect: got 0.
// expect: A decimal holds 28 digits; a count outside them writes digits the value does not carry.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (ratio: (1234.5,)),
  format-number("ratio", significant: 0),
)
