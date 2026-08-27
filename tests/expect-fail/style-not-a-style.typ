// table-style takes the dictionary style() builds, so a value of another type
// carries no properties to apply.
// expect: table-style: style must be a dictionary built with style()
// expect: got "fill: aqua".
// expect: Write table-style(style(fill: aqua)).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  table-style("fill: aqua", locations: cells-body()),
)
