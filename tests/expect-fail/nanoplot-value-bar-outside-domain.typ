// An explicit domain is a window, and the bar of a value outside it stops at
// the track end, but its label has no room kept for it there.
// expect: nanoplot-value-bar: the value is outside the domain, so its label has no room
// expect: got 1000.0.
// expect: Give a domain that holds every value, or label: none to draw the bars alone.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 1000)),
  format-nanoplot("units", plot: nanoplot-value-bar(), domain: (0, 10)),
)
