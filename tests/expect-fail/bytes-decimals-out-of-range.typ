// The formatters that round a mantissa or a byte count take no negative place,
// so their range starts at zero and ends where a decimal does.
// expect: format-bytes: decimals must be between 0 and 28
// expect: got 29.
// expect: A decimal holds 28 places; a count outside them writes digits the value does not carry.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (size: (1536,)),
  format-bytes("size", decimals: 29),
)
