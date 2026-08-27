// A location built by hand rather than by a cells-* function, carrying a part
// this version does not address.
// expect: locations: unknown location part
// expect: got "sidebar"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  table-style(style(fill: aqua), locations: (kind: "location", part: "sidebar")),
)
