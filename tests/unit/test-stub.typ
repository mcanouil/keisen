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
