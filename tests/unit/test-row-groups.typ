// Groups declared rather than derived, for data that carries no column to
// group by. The grouping is editorial: which rows belong together is a
// judgement the document makes, not something the data says.

#import "../../src/parts/stub.typ": table-row-group, table-stub
#import "../../src/parts/summaries.typ": aggregate-sum, summary-rows
#import "../../src/render/plan.typ": build-plan
#import "../../src/spec.typ": build-spec

#let data = (country: ("Denmark", "Sweden", "Norway", "Spain"), units: (1, 2, 3, 4))

#let grouped(..directives) = build-spec(data, directives.pos(), (:))

// --- directive shape ---

#let directive = table-row-group([Nordics], (0, 1, 2))
#assert.eq(directive.kind, "row-group")
#assert.eq(directive.label, [Nordics])
#assert.eq(directive.rows, (0, 1, 2))

// --- groups are built from the directives, in the order they were written ---

#let spec = grouped(
  table-stub(rowname: "country"),
  table-row-group([Nordics], (0, 1, 2)),
  table-row-group([Rest], 3),
)
#assert.eq(spec.groups.map(group => group.label), ([Nordics], [Rest]))
#assert.eq(spec.groups.first().rows, (0, 1, 2))
#assert.eq(spec.groups.last().rows, (3,))

// A predicate reads the row, as every other row selector does.
#let predicate = grouped(table-row-group([Small], row => row.units < 3))
#assert.eq(predicate.groups.first().rows, (0, 1))

// --- later groups win on overlap ---

// Norway is claimed twice, and the second claim is the one that renders: a
// group written later is the correction of the one written earlier.
#let overlapping = grouped(
  table-row-group([Nordics], (0, 1, 2)),
  table-row-group([Scandinavia], (1, 2)),
)
#assert.eq(overlapping.groups.map(group => group.label), ([Nordics], [Scandinavia]))
#assert.eq(overlapping.groups.first().rows, (0,))
#assert.eq(overlapping.groups.last().rows, (1, 2))

// A group left with no rows of its own is dropped rather than printed as a
// label over nothing.
#let emptied = grouped(
  table-row-group([Nordics], (0, 1)),
  table-row-group([Scandinavia], (0, 1)),
)
#assert.eq(emptied.groups.map(group => group.label), ([Scandinavia],))

// --- rows no group claims ---

// They render as a leading nameless block, exactly as an ungrouped table does,
// so a partial grouping loses nothing.
#let partial = grouped(table-row-group([Nordics], (1, 2)))
#let plan = build-plan(partial).rows.filter(entry => entry.part in ("body", "group"))

#assert.eq(plan.map(entry => entry.part), ("body", "body", "group", "body", "body"))
#assert.eq(plan.first().source, 0)
#assert.eq(plan.at(1).source, 3)
#assert.eq(plan.at(2).source, 0)

// Striping counts body rows across the whole table, so the phase does not
// restart under the group label.
#assert.eq(plan.map(entry => entry.stripe), (false, true, false, false, true))

// --- summaries reach a declared group ---

#let summarised = grouped(
  table-row-group([Nordics], (0, 1, 2)),
  summary-rows(functions: (Subtotal: aggregate-sum), columns: ("units",)),
)
#assert.eq(summarised.groups.len(), 1)
