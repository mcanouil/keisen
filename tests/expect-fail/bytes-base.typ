// A byte size is counted in thousands or in 1024s. A third convention would
// have no prefixes to name it with.
// expect: format-bytes: base must be one of "1000", "1024"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (size: (1024, 2048)),
  format-bytes("size", base: 2),
)
