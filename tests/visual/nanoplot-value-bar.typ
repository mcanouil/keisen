// A bar per cell, coloured along a gradient by its value and labelled with it.
// The axis rows label the ends of the track, lined up with the bars.

#import "/lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (product: ("Bolt", "Nut", "Washer", "Screw", "Rebate"), units: (14, 50, 81, 33, -20)),
  format-nanoplot(
    "units",
    plot: nanoplot-value-bar(fill: gradient.linear(rgb("#9ecae1"), rgb("#08306b")), axis: true),
  ),
)
