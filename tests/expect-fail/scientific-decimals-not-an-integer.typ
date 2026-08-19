// This formatter builds its own option dictionary rather than passing through
// format-number, and it reaches the same rounding arithmetic, so it pre-checks
// its decimal count rather than dying in Typst's grammar.
// expect: format-scientific: decimals must be an integer or auto
// expect: got "two"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (mass: (0.000123,)),
  format-scientific("mass", decimals: "two"),
)
