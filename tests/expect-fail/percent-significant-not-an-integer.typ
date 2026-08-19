// A significant-digit count that is not a count passed the exclusivity check,
// because `decimals` was left alone, and then died inside the place arithmetic.
// The formatter the caller wrote is what reports it.
// expect: format-percent: significant must be an integer or none
// expect: got "two"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (share: (0.18234,)),
  format-percent("share", significant: "two"),
)
