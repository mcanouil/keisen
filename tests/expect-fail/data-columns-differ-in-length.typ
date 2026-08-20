// Every column of a column store holds one value per row. A longer column was
// cut to the length of the first one without a word, and a shorter one failed
// as a raw Typst error about an array index.
// expect: data: column price has 3 values, expected 2
// expect: Every column must have the same length.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5, 3.5)),
)
