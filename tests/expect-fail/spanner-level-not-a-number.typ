// A level is a position among the header rows, and everything that reads it
// counts with it: the rows are sorted by it, and a footnote mark is ranked by
// it inverted. Anything else failed as a raw Typst error, and only once a
// footnote reached the spanner.
// expect: table-spanner: level must be a whole number
// expect: got "top"
// expect: Level 1 sits directly above the column labels, and higher levels stack above it.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-spanner([Figures], ("units", "price"), level: "top"),
)
