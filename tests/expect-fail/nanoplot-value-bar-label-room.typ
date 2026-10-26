// The label room is kept on the right of the track, so a label wider than the
// plot leaves no track to draw the bars in.
// expect: nanoplot-value-bar: the label room leaves no track for the bars
// expect: got 4em.
// expect: Widen the plot with width, or shorten the label.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (100, 810)),
  format-nanoplot("units", plot: nanoplot-value-bar(label: value => [#value units sold])),
)
