// The axis of a value bar is switched on or off.
// expect: nanoplot-value-bar: axis must be a boolean
// expect: got "true".
// expect: Give true to draw the axis rows, or false.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 10)),
  format-nanoplot("units", plot: nanoplot-value-bar(axis: "true")),
)
