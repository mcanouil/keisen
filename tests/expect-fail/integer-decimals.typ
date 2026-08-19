// An integer formatter with a decimal count is two instructions that disagree,
// and the count would win silently, since forwarded options come after the
// `decimals: 0` the formatter sets for itself.
// expect: format-integer: decimals and significant do not apply to integers
// expect: Use format-number when a fractional part is wanted.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (count: (1234,)),
  format-integer("count", decimals: 2),
)
