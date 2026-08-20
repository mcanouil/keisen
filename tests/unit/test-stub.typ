// The stub promotes a column to row names, and optionally another to group
// labels. Groups become their own rows in the plan, as repeating subheaders.

#import "../../src/spec.typ": build-spec
#import "../../src/render/plan.typ": build-plan
#import "../../src/parts/stub.typ": table-stub

#let data = (
  product: ("Bolt", "Nut", "Beam"),
  region: ("North", "North", "South"),
  units: (10, 20, 30),
)

#let spec = build-spec(data, (table-stub(rowname: "product", group: "region", label: [Product]),), (:))

// The stub column leaves the ordinary columns and becomes the stub.
#assert.eq(spec.stub.rowname, "product")
#assert.eq(spec.stub.group, "region")
#assert.eq(spec.stub.label, [Product])
#assert.eq(spec.columns, ("units",))

// Groups keep first-appearance order, and carry the rows that belong to them.
#assert.eq(spec.groups.map(group => group.label), ("North", "South"))
#assert.eq(spec.groups.first().rows, (0, 1))
#assert.eq(spec.groups.last().rows, (2,))

// The plan interleaves each group label with its rows.
#let plan = build-plan(spec).rows
#assert.eq(
  plan.map(entry => entry.part),
  ("labels", "group", "body", "body", "group", "body"),
)

// A group label is a level-3 subheader, so it repeats under the column labels.
#assert.eq(plan.at(1).level, 3)
#assert.eq(plan.at(1).source, 0)
#assert.eq(plan.at(4).source, 1)

// Striping still counts body rows alone, across group boundaries.
#assert.eq(plan.filter(entry => entry.part == "body").map(entry => entry.stripe), (false, true, false))

// Without a group column there are no group rows.
#let ungrouped = build-spec(data, (table-stub(rowname: "product"),), (:))
#assert.eq(ungrouped.groups, ())
#assert.eq(build-plan(ungrouped).rows.map(entry => entry.part), ("labels", "body", "body", "body"))

// Indentation levels come from a column of integers.
#let indented = build-spec(
  (product: ("Total", "Bolt"), depth: (0, 1), units: (30, 10)),
  (table-stub(rowname: "product", indent: "depth"),),
  (:),
)
#assert.eq(indented.stub.indent, "depth")
#assert.eq(indented.columns, ("units",))

// --- a numeric stub is not decimal-aligned ---
//
// The decimal metric that pads a column against its separator is computed for
// the data columns alone, so a stub of figures renders ragged where the same
// figures in a data column line up. The reference says so, and the stub arm
// below reads what the renderer emits: `stub-cells` is the call the renderer
// makes for the stub. The data arm is a reference construction, built from the
// same metric the renderer computes, and it is there as the contrast rather
// than as a second reading of the renderer.
//
// The evidence is width. Two figures of different length line up only when the
// shorter one is padded, so a padded column renders them to one width and an
// unpadded one does not.

#import "../../src/format/align.typ": align-slots
#import "../../src/format/number.typ": format-number
#import "../../src/parts/summaries.typ": summary-values
#import "../../src/render/layout.typ": column-cells, metrics, slots-to-content, stub-cells

#let figures = build-spec(
  (year: (1999, 20005), units: (10, 2000.25)),
  (table-stub(rowname: "year"), format-number(auto)),
  (:),
)

#assert.eq(figures.columns, ("units",))

#context {
  let stub = stub-cells(figures)

  // The format reaches the stub: 1999 is written to two decimal places with the
  // group separator the theme names, rather than as the integer it arrived as.
  assert.eq(stub.first(), [#("1" + sym.space.thin + "999.00")])

  // And the two rows keep the widths their digits give them.
  assert(
    measure(stub.first()).width < measure(stub.last()).width,
    message: "a stub is not padded, so a shorter figure stays shorter",
  )

  // The same figures in a data column, through the metric the renderer computes
  // rather than one built here, come out to one width.
  let cells = column-cells(figures)
  let metric = metrics(figures, cells, summary-values(figures)).first()
  let padded = cells.first().map(slots => slots-to-content(align-slots(slots, metric)))
  assert.eq(
    measure(padded.first()).width,
    measure(padded.last()).width,
    message: "a data column is padded against its separator, so its cells share a width",
  )
}

// --- an indented stub sits one step in per level ---
//
// The step is a theme option, and nothing had ever set it: discarding it, so
// every stub row rendered flat, left the whole suite green. Nothing reads a
// built table back, so the rule is named in `layout.typ` and measured here, as
// the padding above is.

#import "../../src/render/layout.typ": stub-body, stub-depths
#import "../../src/theme/options.typ": option, table-options

// The levels themselves, as the renderer reads them: one per row, from the
// column the stub names. Nothing had read these either, so a renderer that gave
// every row a depth of zero left the suite green.
#assert.eq(stub-depths(indented), (0, 1))

// No indent column is no levels, and the array is still one entry per row, so
// the renderer indexes it without asking.
#assert.eq(stub-depths(ungrouped), (0, 0, 0))

// A sparse row store is data with a gap in it: the row that carries no level
// sits flat rather than failing.
#let sparse = build-spec(
  ((product: "Total", depth: 1), (product: "Bolt")),
  (table-stub(rowname: "product", indent: "depth"),),
  (:),
)
#assert.eq(stub-depths(sparse), (1, 0))

#let stepped = build-spec(
  (product: ("Total", "Bolt"), depth: (0, 1), units: (30, 10)),
  (table-stub(rowname: "product", indent: "depth"), table-options(stub-indent-step: 2em)),
  (:),
)

#context {
  let step = option(stepped.options, "stub-indent-step").to-absolute()
  let flat = measure(stub-body(stepped, [Bolt], 0)).width

  assert.eq(
    measure(stub-body(stepped, [Bolt], 1)).width,
    flat + step,
    message: "a stub at depth 1 sits one step in",
  )
  assert.eq(
    measure(stub-body(stepped, [Bolt], 2)).width,
    flat + step * 2,
    message: "a stub at depth 2 sits two steps in",
  )
}
