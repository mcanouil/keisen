// A value bar draws one number as a bar from zero, coloured and labelled by it.
// Length and colour share the zero-based range, and the label gets room of its
// own on the right so it never overflows the cell.

#import "../../lib.typ": nanoplot-value-bar
#import "../../src/format/renderers.typ": (
  _value-bar-fraction, _value-bar-geometry, _value-bar-label-x, _value-bar-room,
)

#let bar = nanoplot-value-bar(fill: gradient.linear(red, blue))
#assert.eq(bar.kind, "nanoplot-renderer")
#assert.eq((bar.readings)(42), (42.0,))
#assert.eq((bar.readings)("x"), ())
#assert.eq(bar.axis, none)
#assert.ne(nanoplot-value-bar(axis: true).axis, none)

#assert.eq(_value-bar-geometry(50, (14, 81)), (start: 0, end: 50 / 81))
#assert.eq(_value-bar-fraction(50, (14, 81)), 50 / 81)
#assert.eq(_value-bar-geometry(-20, (-40, 60)), (start: 20 / 100, end: 40 / 100))

// A value beyond an explicit domain stops at the end of the track.
#assert.eq(_value-bar-geometry(150, (0, 100)), (start: 0, end: 1))
#assert.eq(_value-bar-geometry(-150, (-100, 100)), (start: 0, end: 0.5))

#context {
  let width = 4em.to-absolute()
  let gap = 0.3em.to-absolute()
  let empty = (bar.draw)(50, domain: none, width: 4em)
  assert.eq(measure(empty).width, width)
  assert.eq((nanoplot-value-bar(axis: true).axis)(domain: none, width: 4em, side: "top"), none)

  // The bar end, the gap and the label fit in the cell at both ends of the domain.
  for domain in ((14, 81), (-40, 60), (-90, 10)) {
    let room = _value-bar-room(auto, domain)
    for value in domain {
      let end = _value-bar-geometry(value, domain).end
      let label = measure(str(calc.round(value))).width
      assert(
        (width - room) * end + gap + label <= width + 0.01pt,
        message: "label overflows for " + repr((value, domain)),
      )
    }
  }

  // A negative reading is labelled right of zero, inside the cell.
  let domain = (-40, 60)
  let offset = _value-bar-label-x(-20, domain, auto, width)
  let label = measure("-20").width
  assert(offset >= (width - _value-bar-room(auto, domain)) * 0.4 + gap - 0.01pt)
  assert(offset + label <= width + 0.01pt)

  // The axis takes the height of its labels, and draws with no cell label.
  for plot in (nanoplot-value-bar(axis: true), nanoplot-value-bar(label: none, axis: true)) {
    let ruler = (plot.axis)(domain: (14, 81), width: 4em, side: "bottom")
    assert.eq(measure(ruler).width, width)
    assert(measure(ruler).height > 0pt)
  }
}
