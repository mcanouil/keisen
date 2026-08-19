// A count inside its own range still asks for a place outside one. The zeros
// between the point and the first digit are decimal places too, so ten digits
// of 1e-20 are 29 of them, and a decimal holds 28.
// expect: format-number: significant asks for more decimal places than a decimal holds
// expect: got (significant: 10, places: 29).
// expect: The zeros between the point and the first digit are places too; use format-scientific for a value this small.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (ratio: (1e-20,)),
  format-number("ratio", significant: 10),
)
