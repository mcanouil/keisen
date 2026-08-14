// An infinity is written only when the caller said what to write. Without
// `infinity:` it is refused, as it always was: a column that silently drops an
// unbounded value is a column that lies about its data.
// expect: format-number: value is not a finite number
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table((ratio: (1.5, float.inf)), format-number("ratio"))
