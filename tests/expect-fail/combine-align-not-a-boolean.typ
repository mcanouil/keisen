// `align` switches the split of a combined column on or off, so only a boolean
// says which.
// expect: columns-combine: align must be true or false
// expect: got "no".
// expect: Write align: false to keep the pattern's own content in every row.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (estimate: (1.0,), error: (0.1,)),
  columns-combine("reading", ("estimate", "error"), (estimate, error) => [#estimate (#error)], align: "no"),
)
