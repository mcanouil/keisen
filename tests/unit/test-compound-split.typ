// A combine pattern is called with markers in place of its values, and what it
// returns is split into values, where a source goes, and glue, the text between
// them. Each value then lines up down the column like any decimal number.

#import "../../src/format/compound.typ": flatten, value-marker, split-pattern

#let call(pattern) = pattern(value-marker(0), value-marker(1))
#let kinds(pieces) = pieces.map(piece => if piece.kind == "value" { piece.index } else { "glue" })
#let glue(pieces) = pieces.filter(piece => piece.kind == "glue").map(piece => flatten(piece.body))

// --- flatten ---

#assert.eq(flatten([a]), ([a],))
#assert.eq(flatten([] + [a]), ([a],))
#assert.eq(flatten([#([a] + [b]) c]), flatten([a] + [b] + [ c]))
#assert.eq(flatten([]), ())

// --- patterns that split ---

#let interval = split-pattern(call((low, high) => [#low, #high]), 2)
#assert.eq(kinds(interval), (0, "glue", 1))
#assert.eq(glue(interval), (flatten([, ]),))
#assert.eq(interval.first().wrapper, none)

#let bracketed = split-pattern(call((estimate, error) => [#estimate (#error)]), 2)
#assert.eq(kinds(bracketed), (0, "glue", 1, "glue"))
#assert.eq(glue(bracketed), (flatten([ (]), flatten([)])))

#let added = split-pattern(call((estimate, error) => estimate + [ (] + error + [)]), 2)
#assert.eq(kinds(added), (0, "glue", 1, "glue"))

#let leading = split-pattern(call((low, high) => [from #low to #high]), 2)
#assert.eq(kinds(leading), ("glue", 0, "glue", 1))

// A value wrapped in one element keeps that element as its style.
#let strong-value = split-pattern(call((low, high) => [#strong(low) -- #high]), 2)
#assert.eq(kinds(strong-value), (0, "glue", 1))
#assert.eq(strong-value.first().wrapper.func(), strong)

#let styled-value = split-pattern(call((low, high) => [#text(fill: red, low) #high]), 2)
#assert.eq(kinds(styled-value), (0, "glue", 1))
#assert.eq(repr(styled-value.first().wrapper.func()), "styled")

// The order the pattern writes its values in is the order of the pieces.
#assert.eq(kinds(split-pattern(call((low, high) => [#high, #low]), 2)), (1, "glue", 0))

// --- patterns that do not split ---

// Nested deeper than one wrapper.
#assert.eq(split-pattern(call((low, high) => [#box(strong(low)) #high]), 2), none)
// A value written twice.
#assert.eq(split-pattern(call((low, high) => [#low #low #high]), 2), none)
// A value left out.
#assert.eq(split-pattern(call((low, high) => [#low]), 2), none)
// No value at all.
#assert.eq(split-pattern(call((low, high) => [text]), 2), none)
// A wrapper holding more than the value.
#assert.eq(split-pattern(call((low, high) => [#strong[#low x] #high]), 2), none)

// --- a split is checked against the real call ---
//
// The marker call cannot see a pattern that branches on its values, so the
// split is only kept when putting the real values back where the markers were
// gives exactly what the pattern returns for them.

#import "../../src/format/compound.typ": split-matches

#let agrees(pattern, ..values) = {
  let values = values.pos()
  split-matches(pattern(..range(values.len()).map(value-marker)), pattern(..values), values)
}

#assert(agrees((low, high) => [#low, #high], [0.07], [0.29]))
// `+` flattens a value built of several pieces, markup nests it.
#let currency = ([−], [€], [5.00]).join()
#assert(agrees((low, high) => low + [, ] + high, currency, [1]))
#assert(agrees((low, high) => [#low, #high], currency, [1]))
#assert(agrees((low, high) => [#low, #high], [], [1]))
#assert(agrees((low, high) => [#strong(low) -- #high], currency, [1]))
#assert(agrees((low, high) => [#text(fill: red, low) #high], [0.07], [1]))

// A pattern that drops the error when it is missing.
#let drops = (estimate, error) => if error == [—] [#estimate] else [#estimate (#error)]
#assert(agrees(drops, [1.2], [0.3]))
#assert(not agrees(drops, [1.2], [—]))

// A pattern that picks its glue from a value.
#let picks = (low, high) => if low == [0] [#low to #high] else [#low, #high]
#assert(not agrees(picks, [0], [1]))
