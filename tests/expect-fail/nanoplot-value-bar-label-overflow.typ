// The room is sized from the labels of the ends of the domain, so a label wider
// for another value can run past the cell, and is refused rather than drawn
// over the next column.
// expect: nanoplot-value-bar: the label runs past the cell
// expect: got -5.0.
// expect: Widen the plot with width, or shorten the label.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (-5, 9)),
  format-nanoplot("units", plot: nanoplot-value-bar(label: value => if value < 0 [a big loss here] else [#value])),
)
