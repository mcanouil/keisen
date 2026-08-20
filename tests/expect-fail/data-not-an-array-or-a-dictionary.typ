// Data is a row store or a column store, and nothing else. Anything else
// reached the walk over the rows and failed as a raw Typst error naming a
// method rather than the argument.
// expect: data: data must be an array of rows or a dictionary of columns
// expect: got "units, price"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  "units, price",
)
