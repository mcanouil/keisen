// Widths map a column name to a length, one entry per named column, so a value
// that is not a dictionary names no column at all.
// expect: columns-width: widths must map column names to lengths
// expect: got "4cm"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  columns-width("4cm"),
)
