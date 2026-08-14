// Direction: what must stay relative to the writing direction, and what must
// not. The package aligns cells with `start` and `end` so a right-to-left
// table lays out correctly, and pins the inside of a formatted number to
// left-to-right, because a number reads the same way in every script.

#import "../../src/format/align.typ": align-slots, column-metrics
#import "../../src/render/layout.typ": alignments, infer-alignment
#import "../../src/theme/options.typ": DEFAULTS

#let rows = (
  (_index: 0, item: "Alpha", amount: 1256.75),
  (_index: 1, item: "Beta", amount: 8.5),
)

// --- inferred alignment is direction-relative ---

#assert.eq(infer-alignment(rows, "item"), start)
#assert.eq(infer-alignment(rows, "amount"), end)

// A column of nothing has nothing to infer from, and start is where text goes.
#assert.eq(infer-alignment((), "amount"), start)

#let spec = (
  columns: ("item", "amount"),
  data: rows,
  align: (:),
  options: (:),
)

#assert.eq(alignments(spec), (start, end))

// An explicit alignment is the caller's business, direction-relative or not.
#assert.eq(alignments(spec + (align: (amount: center))), (start, center))

// --- the theme aligns by direction, never by side ---

#for name in ("table-align", "header-align") {
  assert(
    DEFAULTS.at(name) in (start, end, center),
    message: name + " must be direction-relative, so a right-to-left table mirrors with the text",
  )
}

// --- a padded number carries settings of its own ---

// The slots are absolute: the integer hugs the separator from the left in
// every script. Without a direction of its own, the run inherits the
// paragraph's, and 1256.75 renders as 75.256 1 in right-to-left text.
//
// This says only that some set rule wraps the boxes, because that is all a
// document can see: a set rule leaves an opaque `styles` value, so nothing
// here can read the direction back out. What the direction actually is, is
// tested by rendering: tools/direction-check.sh compiles the same table both
// ways and compares the glyph order.
#let slots = (
  kind: "number",
  sign: "",
  prefix: none,
  integer: "1256",
  separator: ".",
  fraction: "75",
  exponent: none,
  suffix: none,
)

#context {
  let padded = align-slots(slots, column-metrics((slots,)))
  assert.eq(
    repr(padded.func()),
    "styled",
    message: "a padded number must carry settings of its own, which is where its direction is pinned",
  )
}

// An opaque value has no slots to pad and is returned untouched, so it follows
// the column alignment like any other content.
#context {
  assert.eq(align-slots([Alpha], column-metrics((slots,))), [Alpha])
}
