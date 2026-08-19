// A significant-digit count resolves to a decimal place, and that place has to
// sit inside a decimal. Forty digits reach a power of ten the type cannot hold,
// which raised in Typst's own grammar before this was pre-checked.
// expect: format-number: significant must be between 1 and 28
// expect: got 40.
// expect: A decimal holds 28 digits; a count outside them writes digits the value does not carry.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (ratio: (1.5,)),
  format-number("ratio", significant: 40),
)
