// `data-colour` carries four options that no test set: `domain`, `reverse`,
// `target` and `missing`. Three of them are value logic, decided in
// `colour-styles` before anything is drawn, so they are asserted here. The
// fourth decides whether the colour reaches the cell or the glyph, which only a
// render shows, and `tests/probe/colour-target.typ` reads it there.
//
// Colours are compared as hex, because a sampled colour comes back in the space
// the palette is mixed in, and the question here is which colour, not how it is
// written.

#import "../../src/data.typ": normalise
#import "../../src/parts/colour.typ": colour-styles, data-colour

#let palette = (rgb("#ff0000"), rgb("#00ff00"))
#let spread = normalise((units: (0, 50, 100)))

#let fills(directive, rows: spread) = {
  colour-styles(directive, rows, "units").pairs().map(((position, style)) => style.fill.to-hex())
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
#assert(halfway != "#ff0000")
#assert(halfway != "#00ff00")

// A value outside the domain is clamped rather than extrapolated, so it draws
// the stop it ran past.
#assert.eq(fills(data-colour(palette, columns: "units", domain: (0, 25)), rows: short).last(), "#00ff00")

// A domain of no width reads as the middle rather than dividing by zero.
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
