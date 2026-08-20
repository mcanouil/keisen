// Every row of a row store is a dictionary of column values. A row of any other
// type failed wherever a column was first read from it, which is far from the
// row that caused it, so the row is named here.
// expect: data: row 1 must be a dictionary
// expect: got "price"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  ((units: 1), "price"),
)
