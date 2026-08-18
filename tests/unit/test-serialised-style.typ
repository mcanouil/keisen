// A serialised style resolved its colours and passed everything else through as
// written. A Typst alignment, a length and a stroke cannot be spelled in JSON,
// so `align`, `inset` and `stroke` had no working spelling at all: the string a
// generator writes reached the renderer and died there, with a raw Typst message
// pointing into the package and reading as a type error the caller could fix.

#import "../../lib.typ" as keisen

#let resolved(style) = keisen._resolve-serialised(
  (
    kind: "display-table",
    data: (a: (1,)),
    styles: ((style: style, part: "body"),),
  ),
  (data, directives, theme) => directives,
).first().style

// An alignment is named, as it is named for a column.
#assert.eq(resolved((align: "center")).align, center)
#assert.eq(resolved((align: "end")).align, end)

// An inset is a length written as a string, as a width is.
#assert.eq(resolved((inset: "4pt")).inset, 4pt)
#assert.eq(resolved((inset: "1em")).inset, 1em)

// Typst takes an inset per side, so a dictionary resolves each side it carries
// and leaves the sides it does not alone.
#assert.eq(resolved((inset: (x: "4pt", y: "2pt"))).inset, (x: 4pt, y: 2pt))

// A stroke is a colour, a thickness, or the two together. The two spellings of
// a string are told apart by what they are: a hex string is a colour and
// everything else is measured.
#assert.eq(resolved((stroke: "#08519c")).stroke, rgb("#08519c"))
#assert.eq(resolved((stroke: "0.5pt")).stroke, 0.5pt)
#assert.eq(
  resolved((stroke: (paint: "#08519c", thickness: "0.5pt"))).stroke,
  (paint: rgb("#08519c"), thickness: 0.5pt),
)

// A dash is a name Typst already reads, so it passes through.
#assert.eq(resolved((stroke: (paint: "#000000", dash: "dashed"))).stroke.dash, "dashed")

// No stroke at all is how a rule is taken off one cell.
#assert.eq(resolved((stroke: none)).stroke, none)

// The properties that were already resolved still are, and a property Typst
// reads as written is untouched.
#assert.eq(resolved((fill: "#eeeeee")).fill, rgb("#eeeeee"))
#assert.eq(resolved((text: (weight: "bold"))).text, (weight: "bold"))
#assert.eq(resolved((text: (fill: "#ffffff"))).text.fill, rgb("#ffffff"))

// A value that is already a Typst value passes through, since the same resolver
// runs over a style a document wrote by hand.
#assert.eq(resolved((align: center, inset: 4pt)).align, center)
#assert.eq(resolved((align: center, inset: 4pt)).inset, 4pt)
