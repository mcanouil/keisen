// A combine builds one column from named sources, so an empty `from` names
// nothing to read and the pattern would be called with no arguments.
// expect: columns-combine: from must name the columns to combine
// expect: got ().
// expect: Give an array of column names, in the order the pattern reads them.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (estimate: (1.0,), error: (0.1,)),
  columns-combine("reading", (), (estimate, error) => [#estimate]),
)
