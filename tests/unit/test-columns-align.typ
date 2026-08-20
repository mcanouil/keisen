// `column-alignments` is the call the renderer makes for the row of columns, and
// it is where the theme's `infer-alignment` is read. Nothing had ever set that
// option, so the branch answering `false` was dead: every column fell back to
// the edge its data suggested, and turning inference off changed nothing that
// anyone watched.
//
// The directives are read elsewhere, and were before this file existed:
// `test-selector-names.typ` holds the named form, `test-directive-order.typ` the
// blanket form and the last-wins rule, both against `spec.align`, and
// `test-direction.typ` holds the inferred edges. What no file read is the step
// from a spec into the row of alignments the renderer emits, with the option
// answering either way.

#import "../../src/parts/columns.typ": columns-align
#import "../../src/render/layout.typ": column-alignments
#import "../../src/spec.typ": build-spec

#let data = (product: ("Bolt", "Nut"), units: (10, 20), note: ("light", "heavy"))
#let aligned(directives, theme) = column-alignments(build-spec(data, directives, theme))

// --- inference on, which is the default ---

// Numbers sit against the end edge and everything else against the start edge.
#assert.eq(aligned((), (:)), (start, end, start))

// A named column takes what it was given, and its neighbours keep the inference.
#assert.eq(aligned((columns-align(center, columns: "units"),), (:)), (start, center, start))

// --- inference off ---

#let uninferred = (infer-alignment: false)

// Nothing is inferred, so an unnamed column sits at the start edge whatever it
// holds. This is the answer the option exists to give.
#assert.eq(aligned((), uninferred), (start, start, start))

// A named column is unaffected: the option decides the fallback, not the answer.
#assert.eq(aligned((columns-align(center, columns: "units"),), uninferred), (start, center, start))
