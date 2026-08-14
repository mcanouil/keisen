// Aggregations run on raw values before formatting, and summary rows take
// their place in the plan at the end of each group and of the body.

#import "../../src/spec.typ": build-spec
#import "../../src/render/plan.typ": build-plan
#import "../../src/parts/stub.typ": table-stub
#import "../../src/parts/summaries.typ": (
  aggregate-count, aggregate-max, aggregate-mean, aggregate-median, aggregate-min,
  aggregate-quantile, aggregate-standard-deviation, aggregate-sum, grand-summary-rows,
  summary-rows, summary-values,
)

// --- the aggregations themselves ---

#let values = (1, 2, 3, 4)

#assert.eq(aggregate-sum(values), 10)
#assert.eq(aggregate-mean(values), 2.5)
#assert.eq(aggregate-min(values), 1)
#assert.eq(aggregate-max(values), 4)
#assert.eq(aggregate-count(values), 4)
#assert.eq(aggregate-median(values), 2.5)
#assert.eq(aggregate-median((3, 1, 2)), 2)

// The sample definition, with n - 1 in the denominator.
#assert.eq(aggregate-standard-deviation((2, 4, 4, 4, 5, 5, 7, 9)), calc.sqrt(32 / 7))

// Linear interpolation between order statistics, matching R's type 7 default.
#assert.eq(aggregate-quantile(0.5)(values), 2.5)
#assert.eq(aggregate-quantile(0)(values), 1)
#assert.eq(aggregate-quantile(1)(values), 4)
#assert.eq(aggregate-quantile(0.25)(values), 1.75)

// Gaps are skipped rather than poisoning the result.
#assert.eq(aggregate-sum((1, none, 3)), 4)
#assert.eq(aggregate-count((1, none, 3)), 2)

// An aggregation of nothing is nothing, not an error.
#assert.eq(aggregate-mean(()), none)

// --- summary rows in the plan ---

#let spec = build-spec(
  (
    product: ("Bolt", "Nut", "Beam"),
    region: ("North", "North", "South"),
    units: (10, 20, 30),
  ),
  (
    table-stub(rowname: "product", group: "region"),
    summary-rows(functions: (Subtotal: aggregate-sum)),
    grand-summary-rows(functions: (Total: aggregate-sum)),
  ),
  (:),
)

#assert.eq(spec.summaries.len(), 1)
#assert.eq(spec.grand-summaries.len(), 1)

#let plan = build-plan(spec)
#assert.eq(
  plan.map(entry => entry.part),
  ("labels", "group", "body", "body", "summary", "group", "body", "summary", "grand-summary"),
)

// A summary row is not a body row, so it takes no stripe.
#assert.eq(plan.filter(entry => entry.part == "summary").all(entry => not entry.stripe), true)

// --- the values themselves ---

#let summaries = summary-values(spec)
#assert.eq(summaries.groups.at(0).at(0).label, "Subtotal")
#assert.eq(summaries.groups.at(0).at(0).values.units, 30)
#assert.eq(summaries.groups.at(1).at(0).values.units, 30)
#assert.eq(summaries.grand.at(0).values.units, 60)

// The stub column carries the summary label, not a value.
#assert.eq("product" in summaries.grand.at(0).values, false)
