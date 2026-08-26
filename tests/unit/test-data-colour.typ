// `data-colour` carries five options that no test set: `domain`, `reverse`,
// `target`, `missing` and `rows`. Each is decided in `colour-styles` before
// anything is drawn, so each is asserted here.
// `tests/probe/colour-target.typ` reads `target` again in a render, because a
// style dictionary says which key the colour went into and only the render says
// what that did to the page.
//
// Colours are compared as hex, because a sampled colour comes back in the space
// the palette is mixed in, and the question here is which colour, not how it is
// written.

#import "../../src/data.typ": normalise
#import "../../src/parts/colour.typ": colour-styles, data-colour
#import "../../src/utils/colour.typ": fraction-of

#let palette = (rgb("#ff0000"), rgb("#00ff00"))
#let spread = normalise((units: (0, 50, 100)))

#let fills(directive, rows: spread) = {
  colour-styles(directive, rows, "units").values().map(style => style.fill.to-hex())
}

// --- the scale spans the data unless a domain is given ---

#let plain = fills(data-colour(palette, columns: "units"))
#assert.eq(plain.first(), "#ff0000")
#assert.eq(plain.last(), "#00ff00")

// --- reverse turns it over ---
//
// The values sit at the two ends and the middle, so reversing maps each row to
// the colour the row opposite it had. Asserted against the plain scale rather
// than against a colour, so the assertion is about the reversal alone.
#let reversed = fills(data-colour(palette, columns: "units", reverse: true))
#assert.eq(reversed.first(), plain.last())
#assert.eq(reversed.last(), plain.first())
#assert.eq(reversed.at(1), plain.at(1))

// --- domain places a value where the caller says, not where the data does ---

#let short = normalise((units: (0, 50)))

// Taken from the data, 50 is the top of the scale.
#assert.eq(fills(data-colour(palette, columns: "units"), rows: short).last(), "#00ff00")

// Given a wider domain, it is halfway up and draws neither stop.
#let halfway = fills(data-colour(palette, columns: "units", domain: (0, 100)), rows: short).last()
#assert(halfway != "#ff0000", message: "a value halfway up the domain is not the bottom stop")
#assert(halfway != "#00ff00", message: "a value halfway up the domain is not the top stop")

// A value outside the domain draws the stop it ran past.
#assert.eq(fills(data-colour(palette, columns: "units", domain: (0, 25)), rows: short).last(), "#00ff00")

// The clamp that puts it there is in `fraction-of`, and the colour above cannot
// see it: sampling past the end of a gradient returns the end, so an
// unclamped 2.0 draws the top stop as surely as a clamped 1.0 does. So the
// clamp is asserted where it lives, and so is the domain of no width, which
// reads as the middle rather than dividing by zero.
#assert.eq(fraction-of(50, 0, 25), 1.0)
#assert.eq(fraction-of(-10, 0, 25), 0.0)
#assert.eq(fraction-of(5, 10, 10), 0.5)

#assert.eq(
  fills(data-colour(palette, columns: "units", domain: (50, 50)), rows: short),
  (halfway, halfway),
)

// --- missing is the colour of a cell the scale cannot place ---

#let gapped = normalise((units: (10, none)))

// Without it, the cell is left alone: one style for the one row that has a value.
#assert.eq(colour-styles(data-colour(palette, columns: "units"), gapped, "units").keys(), ("0",))

#let with-missing = colour-styles(
  data-colour(palette, columns: "units", missing: rgb("#00ffff")),
  gapped,
  "units",
)
#assert.eq(with-missing.keys(), ("0", "1"))
#assert.eq(with-missing.at("1").fill.to-hex(), "#00ffff")

// A column the scale can place nothing in is still a column with gaps in it, so
// every cell takes the missing colour. A filtered table that lost its last
// number is exactly where a reader needs the gaps marked.
#let all-gaps = normalise((units: (none, none)))
#let every-gap = colour-styles(
  data-colour(palette, columns: "units", missing: rgb("#00ffff")),
  all-gaps,
  "units",
)
#assert.eq(every-gap.keys(), ("0", "1"))
#assert.eq(every-gap.at("0").fill.to-hex(), "#00ffff")
#assert.eq(every-gap.at("1").fill.to-hex(), "#00ffff")

// Without a missing colour there is still nothing to say about such a column.
#assert.eq(colour-styles(data-colour(palette, columns: "units"), all-gaps, "units"), (:))

// --- rows narrows the directive to part of the column ---
//
// The span is taken over the rows the predicate keeps, so a single row is a
// domain of no width and sits in the middle of the palette.
#let one-row = colour-styles(data-colour(palette, columns: "units", rows: 0), spread, "units")
#assert.eq(one-row.keys(), ("0",))
#assert.eq(one-row.at("0").fill.to-hex(), halfway)

// --- target says which of the two the colour becomes ---
//
// Filled, the cell carries the colour and the text carries the contrast chosen
// for it. Named for the text, the cell is left alone.

#let filled = colour-styles(data-colour(palette, columns: "units"), spread, "units").at("0")
#assert.eq(filled.fill.to-hex(), "#ff0000")
#assert.eq(filled.text.fill, black)

#let lettered = colour-styles(
  data-colour(palette, columns: "units", target: "text"),
  spread,
  "units",
).at("0")
#assert("fill" not in lettered, message: "a text target leaves the cell unfilled")
#assert.eq(lettered.text.fill.to-hex(), "#ff0000")

// A gap follows the target as any other cell does.
#let lettered-gap = colour-styles(
  data-colour(palette, columns: "units", target: "text", missing: rgb("#00ffff")),
  gapped,
  "units",
).at("1")
#assert("fill" not in lettered-gap, message: "a text target leaves a gap's cell unfilled")
#assert.eq(lettered-gap.text.fill.to-hex(), "#00ffff")
