// `data-colour` carries four options that nothing had ever set: `domain`,
// `reverse`, `target` and `missing`. Each is documented, and each could be
// discarded without a word: the table still compiles, and the colours it draws
// are simply the wrong ones.
//
// One table per option, each with a palette of its own, so an assertion names
// one rule rather than "some fill somewhere".
//
// The page is filled off-white, because Typst writes no #ffffff into a render
// that draws none. So white appearing at all is a glyph drawn white, which is
// the contrast a dark fill asks for, and its absence is the evidence that the
// third table colours the glyph rather than the cell.
//
// A sampled colour is written as oklab, because that is the space the palette is
// mixed in, and a palette of one colour is written as the hex it was given.
//
// The scale reaches the bottom of the domain it was given, and halfway up it.
// expect-svg: fill="oklab(62.796% 0.22486 0.12585)"
// expect-svg: fill="oklab(74.72% -0.00451 0.15267)"
// Taken from the data instead, 50 would be the top of the domain and draw this.
// reject-svg: fill="oklab(86.644% -0.23389 0.1795)"
//
// Reversed, the bottom of the domain draws the far stop.
// expect-svg: fill="oklab(96.798% -0.07137 0.19857)"
// Unreversed, it would draw the near one.
// reject-svg: fill="oklab(45.201% -0.03246 -0.31153)"
//
// The glyph carries the palette colour, and no cell is filled, so nothing asks
// for a white glyph anywhere in the render.
// expect-svg: fill="#08306b"
// reject-svg: fill="#ffffff"
//
// The cell with no value takes the missing fill.
// expect-svg: fill="#00ffff"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm, fill: rgb("#f4f4f4"))

// The domain spans the values in the column unless it is given. Given (0, 100),
// 50 sits halfway and draws a mix; taken from the data, 50 is the maximum and
// draws the far stop exactly.
#display-table(
  (product: ("Bolt", "Nut"), units: (0, 50)),
  columns-label(units: [Units]),
  format-integer("units"),
  data-colour((rgb("#ff0000"), rgb("#00ff00")), columns: "units", domain: (0, 100)),
)

// `reverse` turns the scale over. One row is coloured, at the bottom of the
// domain, so the colour it takes says which end the scale started from.
#display-table(
  (product: ("Bolt", "Nut"), units: (0, 100)),
  columns-label(units: [Units]),
  format-integer("units"),
  data-colour(
    (rgb("#0000ff"), rgb("#ffff00")),
    columns: "units",
    rows: 0,
    domain: (0, 100),
    reverse: true,
  ),
)

// `target: "text"` colours the glyph rather than the cell. Filled, this palette
// is dark enough that the glyph would be drawn white for contrast, so the white
// is what its absence proves.
#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  columns-label(units: [Units]),
  format-integer("units"),
  data-colour(rgb("#08306b"), columns: "units", target: "text"),
)

// `missing` is the fill for a cell the scale cannot place. Without it such a
// cell is left alone, which reads as a gap in the data rather than as one in
// the colouring.
#display-table(
  (product: ("Bolt", "Nut"), units: (10, none)),
  columns-label(units: [Units]),
  // Light enough that its own cell reads in black, so the white the table above
  // rejects is drawn nowhere in this render.
  data-colour(rgb("#dddddd"), columns: "units", missing: rgb("#00ffff")),
)
