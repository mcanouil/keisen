// `table-row-group` takes the label as it is written, so a group can be labelled
// with a number. Two places then read that label, and they read it differently:
// the location DSL compared the raw value and the summaries coerced it to a
// string. A summary and a style disagreed about which group they meant, and
// nothing said so.

#import "../../lib.typ": (
  aggregate-sum, cells-row-groups, cells-summary, summary-rows, table-row-group, table-stub,
)
#import "../../src/locations.typ": expand
#import "../../src/parts/summaries.typ": directives-for, summary-labels
#import "../../src/spec.typ": build-spec

#let data = (
  product: ("Bolt", "Nut", "Beam", "Plate"),
  units: (1250, 860, 430, 2100),
)

#let spec = build-spec(
  data,
  (
    table-stub(rowname: "product"),
    table-row-group(3, (0, 1)),
    table-row-group(4, (2, 3)),
    summary-rows(functions: (Subtotal: aggregate-sum), columns: "units", groups: 3),
  ),
  (:),
)

// The labels reach the spec as written, which is what makes the two readings
// able to differ in the first place.
#assert.eq(spec.groups.map(group => group.label), (3, 4))

// One matcher, so a selector picks the same group on both sides. The summary
// directive is narrowed to the group it names, and only that group produces a
// row.
#assert.eq(summary-labels(directives-for(spec.summaries, 3)), ("Subtotal",))
#assert.eq(summary-labels(directives-for(spec.summaries, 4)), ())

// One summary row, one column: the cell, plus the stub cell carrying the label.
#let summaries = expand(cells-summary(), spec)
#assert.eq(summaries.len(), 2)
#assert.eq(summaries.map(address => address.row).dedup(), ((group: 0, row: 0),))

// And the location DSL agrees: the group the style addresses is the group the
// summary was produced for.
#assert.eq(expand(cells-summary(groups: 3), spec), summaries)
#assert.eq(expand(cells-summary(groups: 4), spec), ())

// A string label still answers to the number that plainly names it, which is
// what a group derived from a numeric column needs: `group-by` writes those
// labels as strings.
#let derived = build-spec(
  (year: (2024, 2024, 2025), product: ("Bolt", "Nut", "Beam"), sales: (1, 2, 3)),
  (
    table-stub(rowname: "product", group: "year"),
    summary-rows(functions: (Subtotal: aggregate-sum), columns: "sales", groups: 2024),
  ),
  (:),
)
#assert.eq(derived.groups.map(group => group.label), ("2024", "2025"))
#assert.eq(summary-labels(directives-for(derived.summaries, "2024")), ("Subtotal",))
#assert.eq(expand(cells-summary(groups: 2024), derived).len(), 2)
#assert.eq(expand(cells-summary(groups: 2025), derived), ())

// The hint that lists the known groups is built eagerly, so it runs on every
// check whether or not the check fails. Joining a numeric label into it died
// with a Typst message about joining types, pointing into the package's own
// source, for a selector that was about to match.
#assert.eq(expand(cells-row-groups(groups: 3), spec), ((part: "row-groups", row: 0, column: none),))
