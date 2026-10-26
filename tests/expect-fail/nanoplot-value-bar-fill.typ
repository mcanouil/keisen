// A fill that is not a colour, a gradient, or a function would be dropped
// without a word, and the bars would come out in the text colour.
// expect: nanoplot-value-bar: fill must be a colour, a gradient, or a function
// expect: got "red".
// expect: Give a colour such as rgb("#c33"), a gradient, or value => colour.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  format-nanoplot("units", plot: nanoplot-value-bar(fill: "red")),
)
