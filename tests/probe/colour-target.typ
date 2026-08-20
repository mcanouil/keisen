// `data-colour(target: ..)` decides whether the colour reaches the cell or the
// glyph inside it. Nothing had ever set it to "text", and nothing in a compile
// test can see which one was painted.
//
// Both tables here name the glyph, and both palettes are dark enough that a
// filled cell would ask for a white glyph to read against. Typst writes no
// #ffffff into a render that draws none, so white appearing at all means a cell
// was filled, and the option was not read. It is the only rule this file
// exercises, so that is the only thing its absence can mean.
//
// The glyph carries the palette colour rather than the cell.
// expect-svg: fill="#08306b"
// A gap follows the same rule, through the colour named for it.
// expect-svg: fill="#402020"
// And neither cell is filled, so nothing asks for a white glyph.
// reject-svg: fill="#ffffff"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm, fill: rgb("#f4f4f4"))

#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  columns-label(units: [Units]),
  format-integer("units"),
  data-colour(rgb("#08306b"), columns: "units", target: "text"),
)

// A substitution gives the gap a glyph to colour, since an empty cell draws
// nothing either way.
#display-table(
  (product: ("Bolt", "Nut"), units: (10, none)),
  columns-label(units: [Units]),
  substitute-missing("units", replacement: [#sym.dash.em]),
  data-colour(rgb("#7f0000"), columns: "units", target: "text", missing: rgb("#402020")),
)
