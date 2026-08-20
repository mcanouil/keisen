// A hidden column exists and is not in the final order, so a spanner over one
// is a contradiction rather than a typo. Reported as unknown, the reader hunts
// for a spelling mistake that is not there.
// expect: table-spanner: column price is hidden
// expect: Drop the columns-hide, or drop the column from the spanner.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  columns-hide("price"),
  table-spanner([Figures], ("units", "price")),
)
