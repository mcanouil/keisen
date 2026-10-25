// A fill function is asked for the colour of each bar, so what it returns is
// only seen once a bar is drawn.
// expect: nanoplot-value-bar: fill must return a colour or a gradient
// expect: got "red".
// expect: Give a function that returns a colour such as rgb("#c33") or a gradient.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  format-nanoplot("units", plot: nanoplot-value-bar(fill: value => "red")),
)
