// A value bar draws one number as a bar from zero, coloured and labelled by it.
// Length and colour share the zero-based range, and the label gets room of its
// own on the right so it never overflows the cell.

#import "../../lib.typ": nanoplot-value-bar
#import "../../src/format/renderers.typ": _value-bar-fraction, _value-bar-geometry

#let bar = nanoplot-value-bar(fill: gradient.linear(red, blue))
#assert.eq(bar.kind, "nanoplot-renderer")
#assert.eq((bar.readings)(42), (42.0,))
#assert.eq((bar.readings)("x"), ())
#assert.eq(bar.axis, none)
#assert.ne(nanoplot-value-bar(axis: true).axis, none)

#assert.eq(_value-bar-geometry(50, (14, 81)), (start: 0, end: 50 / 81))
#assert.eq(_value-bar-fraction(50, (14, 81)), 50 / 81)
#assert.eq(_value-bar-geometry(-20, (-40, 60)), (start: 20 / 100, end: 40 / 100))

#context {
  let drawn = (bar.draw)(50, domain: (14, 81), width: 4em)
  assert.eq(measure(drawn).width, 4em.to-absolute())
  let empty = (bar.draw)(50, domain: none, width: 4em)
  assert.eq(measure(empty).width, 4em.to-absolute())
  assert.eq((nanoplot-value-bar(axis: true).axis)(domain: none, width: 4em, side: "top"), none)
  let ruler = (nanoplot-value-bar(axis: true).axis)(domain: (14, 81), width: 4em, side: "bottom")
  assert.eq(measure(ruler).width, 4em.to-absolute())
}
