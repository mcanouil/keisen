// A column width includes the cell inset on both sides, so one no wider than
// the inset leaves the plot nothing to draw in.
// expect: columns-width: a nanoplot column is narrower than its cell inset
// expect: got 0.8em.
// expect: Give it in em or pt, wider than twice the cell inset.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1, 2, 3),)),
  format-nanoplot("trend", plot: nanoplot-line()),
  columns-width((trend: 0.8em)),
)
