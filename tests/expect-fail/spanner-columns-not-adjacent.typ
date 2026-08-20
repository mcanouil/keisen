// A spanner cell spans as many columns as the spanner names, from the first one
// it covers. Over a gap it therefore covers the column between them as well, and
// labels a column the spanner never named.
// expect: table-spanner: columns units, price are not adjacent
// expect: Reorder them with columns-move so the spanner covers a single run.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), region: ("north", "south"), price: (1.5, 2.5)),
  table-spanner([Figures], ("units", "price")),
)
