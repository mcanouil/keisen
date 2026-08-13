// Footnote marks are numbered in reading order, shared by identical notes, and
// substitutions run before formatting so a gap never reaches a formatter.

#import "../../src/spec.typ": build-spec
#import "../../src/format/apply.typ": apply-formats
#import "../../src/format/number.typ": format-number
#import "../../src/locations.typ": cells-body, cells-column-labels
#import "../../src/parts/marks.typ": assign-marks, marks-for
#import "../../src/parts/notes.typ": table-footnote
#import "../../src/parts/substitutions.typ": substitute-missing, substitute-zero

// --- reading order ---

// Written body-first, but the column label is read first, so it takes mark 1.
#let spec = build-spec(
  (units: (10, 20)),
  (
    table-footnote([On the body.], locations: cells-body(columns: "units", rows: 1)),
    table-footnote([On the label.], locations: cells-column-labels()),
  ),
  (:),
)
#let footnotes = assign-marks(spec)

// numbering() returns a string, which super() renders as readily as content.
#assert.eq(footnotes.at(1).mark, "1")
#assert.eq(footnotes.at(0).mark, "2")
#assert.eq(marks-for(footnotes, "column-labels", none, "units"), ("1",))
#assert.eq(marks-for(footnotes, "body", 1, "units"), ("2",))
#assert.eq(marks-for(footnotes, "body", 0, "units"), ())

// --- identical notes share one mark ---

#let repeated = assign-marks(build-spec(
  (units: (10, 20)),
  (
    table-footnote([Same caveat.], locations: cells-body(columns: "units", rows: 0)),
    table-footnote([Same caveat.], locations: cells-body(columns: "units", rows: 1)),
  ),
  (:),
))
#assert.eq(repeated.map(footnote => footnote.mark), ("1", "1"))

// --- an explicit mark is used as given ---

#let explicit = assign-marks(build-spec(
  (units: (10,)),
  (table-footnote([Bespoke.], locations: cells-body(), mark: [#sym.dagger]),),
  (:),
))
#assert.eq(explicit.first().mark, [#sym.dagger])

// --- a footnote with no location is an unmarked note ---

#let unmarked = assign-marks(build-spec((units: (10,)), (table-footnote([No mark.]),), (:)))
#assert.eq(unmarked.first().mark, none)

// --- substitutions run before formatting ---

#let rows = build-spec((units: (none, 0, 5)), (), (:)).data

#assert.eq(
  apply-formats(rows, (), "units", substitutions: (substitute-missing("units", replacement: [--]),)),
  ([--], 0, 5),
)

#assert.eq(
  apply-formats(rows, (), "units", substitutions: (substitute-zero("units", replacement: [nil]),)).at(1),
  [nil],
)

// A gap is replaced rather than handed to a formatter that would refuse it.
#let formatted = apply-formats(
  rows,
  (format-number("units", decimals: 1),),
  "units",
  substitutions: (substitute-missing("units", replacement: [--]),),
)
#assert.eq(formatted.first(), [--])
#assert.eq(formatted.last().integer, "5")
