// A spanner labels a run of columns, so an empty list leaves it labelling
// nothing. The run is measured from the first and last position it covers, and
// with no column to cover, that measurement failed as a raw Typst error about
// an empty array.
// expect: table-spanner: spanner covers no columns
// expect: Name at least one column for the spanner to span.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-spanner([Figures], ()),
)
