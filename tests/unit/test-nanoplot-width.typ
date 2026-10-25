// A nanoplot column sizes itself: the plot's width plus the cell inset on both
// sides, unless `columns-width` names it, in which case the plot gets what the
// inset leaves.

#import "../../lib.typ": display-table, format-nanoplot, nanoplot-line, table-options
#import "../../src/format/apply.typ": content-width, nanoplot-track, widest-nanoplot

#let directive = format-nanoplot("trend", plot: nanoplot-line(), width: 4em)
#assert.eq(content-width(directive, auto, 0.5em), 4em)
#assert.eq(content-width(directive, 6em, 0.5em), 5em)
#assert.eq(nanoplot-track(directive, 0.5em), 5em)
// The horizontal inset is what counts.
#assert.eq(content-width(directive, 6em, (x: 0.5em, y: 2pt)), 5em)
#assert.eq(nanoplot-track(directive, (x: 0.5em, y: 2pt)), 5em)
#assert.eq(nanoplot-track(directive, (left: 1em, rest: 2pt)), 4em + 1em + 2pt)
#assert.eq(nanoplot-track(directive, (top: 1em)), 4em)
// A side wins over `x`, and each side is read on its own.
#assert.eq(content-width(directive, 8em, (left: 0.5em, right: 2em)), 5.5em)
#assert.eq(nanoplot-track(directive, (left: 0.5em, right: 2em)), 6.5em)
#assert.eq(nanoplot-track(directive, (x: 1em, left: 0.5em)), 5.5em)
// The widest plot names the column.
#let wide = format-nanoplot("trend", plot: nanoplot-line(), width: 6em)
#assert.eq(widest-nanoplot((directive, wide, directive)), wide)

#context {
  let table = display-table(
    (trend: ((1, 2, 3), (3, 2, 1))),
    format-nanoplot("trend", plot: nanoplot-line(), width: 4em),
  )
  assert.eq(measure(table).width, 5em.to-absolute() + 0pt)
}

// A set table width does not stretch a nanoplot column: the cell is laid out in
// its own track, and a stretched track would be wider than the plot.
#let probe = nanoplot-line() + (
  draw: (value, domain: none, width: 4em, height: 0.8em) => layout(size => {
    assert(size.width <= 5em.to-absolute() + 0.1pt, message: "nanoplot track stretched to " + repr(size.width))
    box(width: width, height: height)
  }),
)
#context {
  let _ = measure(display-table(
    (name: ("a", "b"), trend: ((1, 2, 3), (3, 2, 1))),
    format-nanoplot("trend", plot: probe, width: 4em),
    table-options(table-width: 20em),
  ))
}
