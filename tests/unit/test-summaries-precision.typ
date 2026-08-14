// Aggregations keep the precision the formatters promise, accept the inputs
// they accept, and honour the selectors they advertise.

#import "../../src/spec.typ": build-spec
#import "../../src/render/plan.typ": build-plan
#import "../../src/parts/stub.typ": table-stub
#import "../../src/parts/summaries.typ": (
  aggregate-count, aggregate-max, aggregate-min, aggregate-sum, summary-rows, summary-values,
)

// --- decimals stay decimals where no arithmetic forces otherwise ---

#assert.eq(aggregate-max((decimal("12345678901234567890.12"), decimal("1"))), decimal("12345678901234567890.12"))
#assert.eq(aggregate-min((decimal("0.1"), decimal("0.2"))), decimal("0.1"))
#assert.eq(aggregate-sum(("0.1", "0.1", "0.1")), decimal("0.3"))

// --- numeric strings aggregate as readily as they format ---

#assert.eq(aggregate-sum(("10", "20")), decimal("30"))

// --- count counts values, of whatever type ---

#assert.eq(aggregate-count(("Bolt", "Nut")), 2)
#assert.eq(aggregate-count((1, none, "")), 1)

// --- a groups selector narrows the rows it produces ---

#let spec = build-spec(
  (product: ("a", "b"), region: ("North", "South"), units: (1, 2)),
  (
    table-stub(rowname: "product", group: "region"),
    summary-rows(functions: (Subtotal: aggregate-sum), groups: ("North",)),
  ),
  (:),
)

#assert.eq(summary-values(spec).groups.at(0).len(), 1)
#assert.eq(summary-values(spec).groups.at(1).len(), 0)

// The plan agrees, so South gets no summary row at all.
#assert.eq(
  build-plan(spec).rows.map(entry => entry.part),
  ("labels", "group", "body", "summary", "group", "body"),
)

// --- a numeric group selector matches the label it names ---

// Group labels are strings, since group-by stringifies the column. The location
// DSL coerces numbers the same way, and the two must agree.
#import "../../src/locations.typ": cells-row-groups, expand
#import "../../src/parts/summaries.typ": directives-for

#let numeric = build-spec(
  (name: ("a", "b"), year: (2023, 2024), units: (1, 2)),
  (
    table-stub(rowname: "name", group: "year"),
    summary-rows(functions: (Subtotal: aggregate-sum), groups: 2023),
  ),
  (:),
)

#assert.eq(expand(cells-row-groups(groups: 2023), numeric).len(), 1)
#assert.eq(directives-for(numeric.summaries, "2023").len(), 1)
#assert.eq(directives-for(numeric.summaries, "2024").len(), 0)
#assert.eq(summary-values(numeric).groups.at(0).len(), 1)
#assert.eq(summary-values(numeric).groups.at(1).len(), 0)
