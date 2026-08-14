// Separators the theme decides, and infinity written as content.
//
// A French or German table writes 1 234,56 in every numeric column, so the
// convention is set once on the theme rather than repeated on every directive.
// The theme is not resolved until render time, so a number directive carries
// how to build its formatter rather than the formatter itself.

#import "../../src/format/apply.typ": apply-formats, formatter-for
#import "../../src/format/bytes.typ": format-bytes
#import "../../src/format/number.typ": format-number
#import "../../src/format/scientific.typ": format-scientific
#import "../../src/theme/options.typ": DEFAULTS

#let rows = ((amount: 1234.5, _index: 0),)
#let french = (number-group-separator: sym.space.nobreak, number-decimal-separator: ",")

// --- the keys exist and carry the package's own defaults ---

#assert.eq(DEFAULTS.at("number-group-separator"), sym.space.thin)
#assert.eq(DEFAULTS.at("number-decimal-separator"), ".")

// --- auto follows the theme ---

#let cell(directive, options: (:)) = apply-formats(
  rows,
  (directive,),
  "amount",
  options: options,
).first()

#assert.eq(cell(format-number("amount")).integer, "1" + sym.space.thin + "234")
#assert.eq(cell(format-number("amount")).separator, ".")

#assert.eq(cell(format-number("amount"), options: french).integer, "1" + sym.space.nobreak + "234")
#assert.eq(cell(format-number("amount"), options: french).separator, ",")

// An argument the caller wrote wins over the theme, as everywhere else.
#let explicit = format-number("amount", group-separator: ".", decimal-separator: ",")
#assert.eq(cell(explicit, options: french).integer, "1.234")

// The rest of the family reaches the same defaults, since they all end in
// format-value: bytes groups its integer, and a mantissa has only a point.
#assert.eq(
  apply-formats(((size: 1536, _index: 0),), (format-bytes("size"),), "size", options: french)
    .first()
    .separator,
  ",",
)
#assert.eq(cell(format-scientific("amount"), options: french).separator, ",")

// --- infinity ---

// A number directive holds no formatter of its own: without the theme there is
// nothing to build one from, and a formatter built from a separator the
// document did not ask for would be worse than none.
#assert.eq(format-number("amount").function, none)

#let unbounded = ((amount: float.inf, _index: 0), (amount: -float.inf, _index: 1))
#let limits = apply-formats(unbounded, (format-number("amount", infinity: [∞]),), "amount")
#assert.eq(limits.first(), [∞])
#assert.eq(limits.last(), [-] + [∞])

// A finite value in the same column is formatted as it always was.
#assert.eq(
  apply-formats(
    ((amount: 2.5, _index: 0),),
    (format-number("amount", infinity: [∞]),),
    "amount",
  ).first().fraction,
  "50",
)

// --- the resolver is reachable on its own ---

// Summary cells format through the same directive without going through
// apply-formats, so the resolution lives where both can reach it.
#assert.eq((formatter-for(format-number("amount"), french))(1234.5).separator, ",")
