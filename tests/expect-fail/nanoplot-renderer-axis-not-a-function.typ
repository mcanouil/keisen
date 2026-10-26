// A renderer's axis is none or a function. Overriding it with false is the
// natural way to ask for no axis, and it is the wrong one.
// expect: format-nanoplot: axis must be none or a function
// expect: got false.
// expect: Give none for no axis.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line() + (axis: false)),
)
