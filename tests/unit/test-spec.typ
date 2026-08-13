// Directives fold into the spec dictionary in declaration order, and the
// result is validated once, at the end.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/header.typ": table-header
#import "../../src/parts/columns.typ": columns-hide, columns-label
#import "../../src/parts/notes.typ": table-source-note
#import "../../src/format/number.typ": format-number

#let spec = build-spec(
  (mass: (1.5, 2.5), name: ("a", "b")),
  (
    table-header(title: [Masses]),
    columns-label(mass: [Mass]),
    columns-hide("name"),
    format-number("mass", decimals: 1),
    table-source-note([Source: scale.]),
  ),
  (:),
)

#assert.eq(spec.kind, "display-table")
#assert.eq(spec.columns, ("mass",))
#assert.eq(spec.hidden, ("name",))
#assert.eq(spec.labels.mass, [Mass])
#assert.eq(spec.header.title, [Masses])
#assert.eq(spec.header.subtitle, none)
#assert.eq(spec.formats.len(), 1)
#assert.eq(spec.source-notes, ([Source: scale.],))

// Data is normalised on the way in, so predicates see _index.
#assert.eq(spec.data.first()._index, 0)

// A hidden column stays available to formatters and predicates.
#assert.eq(spec.data.first().name, "a")

// Later directives of the same kind win for the keys they set.
#let overridden = build-spec(
  (mass: (1,)),
  (columns-label(mass: [First]), columns-label(mass: [Second])),
  (:),
)
#assert.eq(overridden.labels.mass, [Second])

// Options come from the theme argument.
#assert.eq(build-spec((mass: (1,)), (), (row-striping: true)).options.row-striping, true)

// An empty table is a table, not a failure.
#assert.eq(build-spec((:), (), (:)).columns, ())
