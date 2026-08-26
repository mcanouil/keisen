// A summary label had one answer written into the renderer: the start edge,
// whatever the column beneath it did. On a table with no stub the label sits in
// the first column, so a numeric first column, or one named by columns-align,
// put the label against the opposite edge from every other cell above it.
//
// The rule is named here so a test can read what the renderer emits, as
// `label-alignment` and `stub-alignment` beside it are.

#import "../../src/parts/columns.typ": columns-align
#import "../../src/render/layout.typ": column-alignments, summary-label-alignment
#import "../../src/spec.typ": build-spec

// With a stub, the label is a stub cell and follows the stub's own edge.
#assert.eq(summary-label-alignment((end, start), true, center), center)

// With no stub, it follows the first column and the stub edge says nothing.
#assert.eq(summary-label-alignment((end, start), false, center), end)
#assert.eq(summary-label-alignment((start, end), false, center), start)

// A table whose every column is hidden still draws a grand summary, and there
// is no column left for its label to follow. Reading position 0 of nothing is
// what a Typst index error is made of, so the edge is answered before the
// lookup.
#assert.eq(summary-label-alignment((), false, center), start)

// And as the renderer reads it, through the alignments of a spec: a numeric
// first column sits against the end edge, and so does the label beneath it.
#let data = (units: (10, 20), note: ("light", "heavy"))
#let alignments = column-alignments(build-spec(data, (), (:)))
#assert.eq(alignments.first(), end)
#assert.eq(summary-label-alignment(alignments, false, start), end)

// Named rather than inferred, the label follows the name.
#let named = column-alignments(build-spec(data, (columns-align(center, columns: "units"),), (:)))
#assert.eq(summary-label-alignment(named, false, start), center)
