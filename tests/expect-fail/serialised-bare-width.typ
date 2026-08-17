// A width with no unit could only be given one by guessing, so it is refused.
// expect: width: a width needs a unit
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: (units: (1, 2)),
  widths: (units: 2),
))
