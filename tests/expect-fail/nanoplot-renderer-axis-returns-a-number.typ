// An axis is drawn into a table cell, so it returns content or none.
// expect: format-nanoplot: axis must return content or none
// expect: got 3.
// expect: Return none for no axis on that side.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line() + (axis: (domain: none, width: none, side: none) => 3)),
)
