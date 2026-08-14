// The footnote rows, addressed as the source notes already were.
//
// A footnote row is numbered by its position in the rendered footer: the marked
// notes in the order their marks were assigned, then the unmarked ones. That
// order is settled by mark assignment rather than by the order the directives
// were written, so it arrives on the spec, and a location expanded before marks
// exist says so rather than quietly matching nothing.

#import "../../src/locations.typ": PARTS, cells-body, cells-footnotes, expand
#import "../../src/parts/marks.typ": assign-marks, footer-notes
#import "../../src/parts/notes.typ": table-footnote
#import "../../src/parts/stub.typ": table-stub
#import "../../src/spec.typ": build-spec

#let spec = build-spec(
  (name: ("a", "b"), units: (1, 2)),
  (
    table-stub(rowname: "name"),
    table-footnote([Explains the table.]),
    table-footnote([Marks a cell.], locations: cells-body(rows: 0, columns: "units")),
  ),
  (:),
)

// --- the vocabulary has the part ---

#assert.eq(PARTS.footnotes, "footnotes")

#let location = cells-footnotes()
#assert.eq(location.kind, "location")
#assert.eq(location.part, PARTS.footnotes)
#assert.eq(location.notes, auto)

// --- expansion, once the footer is known ---

// Two footnotes, so two rows: the marked one prints first, the unmarked one
// under it, whichever order they were written in.
#let footer = spec + (footnote-rows: 2)

#assert.eq(
  expand(cells-footnotes(), footer),
  ((part: "footnotes", row: 0, column: none), (part: "footnotes", row: 1, column: none)),
)
#assert.eq(expand(cells-footnotes(notes: 1), footer), ((part: "footnotes", row: 1, column: none),))
#assert.eq(expand(cells-footnotes(notes: (0, 1)), footer).len(), 2)
#assert.eq(expand(cells-footnotes(notes: note => note._index > 0), footer).len(), 1)

// A table with no footnotes has no footnote rows to address.
#assert.eq(expand(cells-footnotes(), spec + (footnote-rows: 0)), ())

// --- the footer prints marked notes in mark order ---

// Marks are numbered in reading order, so the note written first here is the
// second a reader meets. Printing the footer in directive order would list mark
// 2 above mark 1, and this location would then address rows nobody could
// predict by counting marks.
#let crossed = build-spec(
  (name: ("a", "b", "c"), units: (1, 2, 3)),
  (
    table-footnote([Written first, marks the last row.], locations: cells-body(rows: 2)),
    table-footnote([Written second, marks the first row.], locations: cells-body(rows: 0)),
    table-footnote([Unmarked, and printed last.]),
  ),
  (:),
)
#let footer = footer-notes(assign-marks(crossed))
#assert.eq(footer.map(footnote => footnote.mark), ("1", "2", none))
#assert.eq(footer.first().note, [Written second, marks the first row.])
