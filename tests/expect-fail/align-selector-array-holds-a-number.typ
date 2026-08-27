// A column selector names columns, so a number written among the names is a
// typo. It used to be dropped in silence, which left the alignment landing on
// fewer columns than the caller wrote and said nothing about why.
// expect: columns: selector must be auto, a name, an array of names, or a predicate
// expect: got ("units", 42).
// expect: Write "units", ("units", "price"), or name => name != "units".

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: (1, 2), price: (3, 4)),
  columns-align(end, columns: ("units", 42)),
)
