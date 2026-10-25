// The base label of the axis starts at the track start and must end before the
// peak label begins, so a track narrower than it is refused.
// expect: nanoplot-value-bar: the axis label of the domain's low is wider than the track
// expect: got -200.0.
// expect: Widen the plot with width, or shorten the label.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (-200, 810)),
  format-nanoplot("units", plot: nanoplot-value-bar(label: value => [#value units], axis: true)),
)
