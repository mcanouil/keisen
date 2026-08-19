// The exponent is typeset as a power or written as an e. A third spelling is a
// typo, and one that would otherwise render as a power without comment.
// expect: format-scientific: exponent must be one of "power", "e"
// expect: got "superscript"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (size: (12345, 678)),
  format-scientific("size", exponent: "superscript"),
)
