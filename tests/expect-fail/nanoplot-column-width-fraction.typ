// A nanoplot is drawn at a fixed width, so a fractional column has no width to
// draw in.
// expect: columns-width: a nanoplot column needs a fixed width
// expect: got 1fr.
// expect: Give it in em or pt, wider than twice the cell inset.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1, 2, 3),)),
  format-nanoplot("trend", plot: nanoplot-line()),
  columns-width((trend: 1fr)),
)
