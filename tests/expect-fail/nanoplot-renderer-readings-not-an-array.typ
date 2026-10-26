// A renderer's readings return the numbers in a cell, so anything but an array
// is refused before the core counts it.
// expect: format-nanoplot: readings must return an array of numbers
// expect: got 0.
// expect: Return () for a value the renderer cannot read.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line() + (readings: value => 0)),
)
