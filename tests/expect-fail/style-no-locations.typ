// A style with nowhere to go styles nothing, which reads as the style itself
// failing rather than as an address that was never given.
// expect: table-style: no locations given
// expect: Name cells with cells-body(), cells-column-labels(), and the rest.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  table-style(style(fill: aqua)),
)
