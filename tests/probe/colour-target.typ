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
// The rejection is the assertion that reads the option. The two expectations
// below say the colour reached the page at all, and a filled cell would satisfy
// them as readily as a coloured glyph, since a fill and a glyph are written the
// same way. Which of the two it went into is asserted in
// `tests/unit/test-data-colour.typ`, on the style dictionary itself.
//
// expect-svg: fill="#08306b"
// expect-svg: fill="#402020"
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
