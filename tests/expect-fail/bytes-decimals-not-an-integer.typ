// The byte formatter builds its own option dictionary, as the scientific one
// does, and pre-checks its decimal count the same way rather than handing a
// word to the rounding arithmetic.
// expect: format-bytes: decimals must be an integer or auto
// expect: got "one"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (size: (1536,)),
  format-bytes("size", decimals: "one"),
)
