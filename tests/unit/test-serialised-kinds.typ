// The six directive kinds a serialised specification could not reach. Each
// takes no closure, so each is expressible as data; they were absent by
// omission rather than by nature.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#let spec = resolve-serialised(
  (
    kind: "display-table",
    data: (
      product: ("Bolt", "Nut", "Beam"),
      units: (10, 20, 30),
      price: (1.5, 2.5, 3.5),
      code: ("B", "N", "P"),
    ),
    "row-groups": ((label: "Fasteners", rows: (0, 1)),),
    hidden: "code",
    moves: ((columns: "price", before: "units"),),
    widths: (units: "2cm", price: "1fr", product: "auto"),
    alignments: ((alignment: "center", columns: "product"),),
    colours: ((palette: ("#f7fbff", "#08519c"), columns: "units"),),
    footnotes: (
      (
        note: "Counted at the depot.",
        locations: (part: "body", columns: "units", rows: 0),
      ),
    ),
  ),
  build-spec,
)

// A declared group claims the rows it names, and what no group claims leads the
// body as a nameless block.
#assert.eq(spec.groups.map(group => group.label), ([Fasteners],))
#assert.eq(spec.groups.first().rows, (0, 1))

#assert.eq(spec.hidden, ("code",))

// The move is resolved once every directive has landed, so price sits ahead of
// units in the rendered order.
#assert.eq(spec.columns, ("product", "price", "units"))

// A width arrives as a string and is read into the length it spells.
#assert.eq(spec.widths.units, 2cm)
#assert.eq(spec.widths.price, 1fr)
#assert.eq(spec.widths.product, auto)

#assert.eq(spec.align.product, center)

#assert.eq(spec.colours.len(), 1)
#assert.eq(spec.colours.first().palette, (rgb("#f7fbff"), rgb("#08519c")))
#assert.eq(spec.colours.first().target, "fill")

#assert.eq(spec.footnotes.len(), 1)
#assert.eq(spec.footnotes.first().mark, auto)
#assert.eq(spec.footnotes.first().locations.part, "body")
#assert.eq(spec.footnotes.first().locations.columns, "units")

// A footnote may carry several locations, as a hand-written one may.
#let several = resolve-serialised(
  (
    kind: "display-table",
    data: (units: (1, 2)),
    footnotes: (
      (
        note: "Two places.",
        locations: ((part: "body", columns: "units"), (part: "column-labels", columns: "units")),
        mark: "dagger",
      ),
    ),
  ),
  build-spec,
)
#assert.eq(several.footnotes.first().locations.len(), 2)
#assert.eq(several.footnotes.first().mark, [dagger])
