// A location is what cells-body() and the rest build, so a dictionary of
// anything else addresses nothing.
// expect: locations: not a location
// expect: got (part: "body").
// expect: Use cells-body(), cells-column-labels(), and the other cells-* functions.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  table-style(style(fill: aqua), locations: (part: "body")),
)
