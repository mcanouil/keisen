// The width of a nanoplot column is taken from the horizontal cell inset, so an
// inset that is not a length or a dictionary of lengths has no width to give.
// expect: cell-inset: a table with a nanoplot column needs an inset given as a length
// expect: got (1em, 2em).
// expect: Give a length or a dictionary of lengths, such as (x: 0.5em).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1, 2, 3),)),
  format-nanoplot("trend", plot: nanoplot-line()),
  table-options(cell-inset: (1em, 2em)),
)
