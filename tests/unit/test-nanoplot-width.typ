// A nanoplot column sizes itself: the plot's width plus the cell inset on both
// sides, unless `columns-width` names it, in which case the plot gets what the
// inset leaves.

#import "../../lib.typ": display-table, format-nanoplot, nanoplot-line
#import "../../src/format/apply.typ": content-width, nanoplot-track

#let directive = format-nanoplot("trend", plot: nanoplot-line(), width: 4em)
#assert.eq(content-width(directive, auto, 0.5em), 4em)
#assert.eq(content-width(directive, 6em, 0.5em), 5em)
#assert.eq(nanoplot-track(directive, 0.5em), 5em)
// The horizontal inset is what counts.
#assert.eq(content-width(directive, 6em, (x: 0.5em, y: 2pt)), 5em)
#assert.eq(nanoplot-track(directive, (x: 0.5em, y: 2pt)), 5em)
#assert.eq(nanoplot-track(directive, (left: 1em, rest: 2pt)), 6em)
#assert.eq(nanoplot-track(directive, (top: 1em)), 4em)

#context {
  let table = display-table(
    (trend: ((1, 2, 3), (3, 2, 1))),
    format-nanoplot("trend", plot: nanoplot-line(), width: 4em),
  )
  assert.eq(measure(table).width, 5em.to-absolute() + 0pt)
}
