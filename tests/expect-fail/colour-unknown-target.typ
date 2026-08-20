// A colour goes into the cell or into the glyph, and nothing else. A third
// spelling used to reach the renderer and colour neither, so the column simply
// came out plain.
// expect: data-colour: target must be fill or text
// expect: got "glyph"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  data-colour(rgb("#08306b"), columns: "units", target: "glyph"),
)
