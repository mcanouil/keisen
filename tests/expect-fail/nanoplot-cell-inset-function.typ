// A function is not an inset a nanoplot column can take its width from.
// expect: cell-inset: a table with a nanoplot column needs an inset given as a length
// expect: got (..) => ...
// expect: Give a length or a dictionary of lengths, such as (x: 0.5em).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1, 2, 3),)),
  format-nanoplot("trend", plot: nanoplot-line()),
  table-options(cell-inset: x => 1em),
)
