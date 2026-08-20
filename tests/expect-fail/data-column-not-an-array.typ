// A column store maps every name to an array of values. The type is read before
// the length, because reading the length of anything else fails as a raw Typst
// error before the column can be named.
// expect: data: column price is not an array
// expect: got 1.5.
// expect: A column store maps each name to an array of values.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: 1.5),
)
