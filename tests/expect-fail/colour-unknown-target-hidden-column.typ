// The target is read where the directive is validated, not where the column is
// drawn, so a hidden column refuses the same spelling a drawn one refuses. Left
// to the renderer, a misspelling on a column nobody draws was read by nobody.
// expect: data-colour: target must be fill or text
// expect: got "glyph"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  columns-hide("units"),
  data-colour(rgb("#08306b"), columns: "units", target: "glyph"),
)
