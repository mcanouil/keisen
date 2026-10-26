// An array of readings holds numbers, since the domain is spanned across them.
// expect: format-nanoplot: readings must return an array of numbers
// expect: got ("a",).
// expect: Return () for a value the renderer cannot read.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line() + (readings: value => ("a",))),
)
