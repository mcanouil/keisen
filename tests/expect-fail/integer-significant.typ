// Significant digits ask for a fractional part as readily as a decimal count
// does, so an integer formatter refuses both keys under one message.
// expect: format-integer: decimals and significant do not apply to integers
// expect: Use format-number when a fractional part is wanted.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (count: (1234,)),
  format-integer("count", significant: 2),
)
