// The pattern is called with one argument per source column, so a value that is
// not a function has nothing to call.
// expect: columns-combine: pattern must be a function of the source columns
// expect: got "not a function".
// expect: Write (estimate, error) => [#estimate (#error)], one parameter per source.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (estimate: (1.0,), error: (0.1,)),
  columns-combine("reading", ("estimate", "error"), "not a function"),
)
