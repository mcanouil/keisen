// An entry of auto names the column and gives it no width, which a nanoplot
// column cannot draw in either.
// expect: columns-width: a nanoplot column needs a fixed width
// expect: got auto.
// expect: Give it in em or pt, wider than twice the cell inset.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1, 2, 3),)),
  format-nanoplot("trend", plot: nanoplot-line()),
  columns-width((trend: auto)),
)
