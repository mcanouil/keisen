// A plot width is a fixed length: the column is sized from it, and a percentage
// has no column width to be a share of until the column has one.
// expect: format-nanoplot: width must be a length
// expect: got 50%.
// expect: Give it in em or pt.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line(), width: 50%),
)
