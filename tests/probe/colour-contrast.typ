// data-colour picks the text colour per cell from the background's relative
// luminance, so a value deep in the palette is not black on near-black. Nothing
// in a compile test can see that: the wrong contrast compiles perfectly and is
// simply unreadable.
//
// The page is filled off-white deliberately. Typst writes no #ffffff into a
// render that draws none, so pure white appearing at all is a glyph drawn in
// white: the contrast the deepest cell asked for. Without data-colour the whole
// column is black on nothing and the assertion fails.
//
// The fills themselves are written as oklab, because that is the space the
// palette is mixed in, so the deep end of the palette is named as Typst writes
// it rather than as the hex it was given.
//
// expect-svg: fill="#ffffff"
// expect-svg: fill="oklab(32.2

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm, fill: rgb("#f4f4f4"))

#display-table(
  (product: ("Bolt", "Nut", "Beam", "Plate"), units: (1, 400, 900, 2100)),
  columns-label(units: [Units]),
  format-integer("units"),
  data-colour(("#ffffff", "#08306b"), columns: "units"),
)
