// The symbol goes before the number or after it. Anything else is a typo that
// would otherwise be silently ignored.
// expect: format-currency: position must be one of "start", "end"
// expect: got center

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (price: (1.5, 2.5)),
  format-currency("price", position: center),
)
