// A specification that survives JSON: formatters and aggregations named rather
// than passed, and predicates written as comparisons rather than closures.

#import "../../lib.typ": display-table
#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-predicate, resolve-serialised

// --- predicates ---

#let below = resolve-predicate((column: "margin", op: "<", value: 0.05))
#assert.eq(below((margin: 0.03)), true)
#assert.eq(below((margin: 0.5)), false)

// A missing value satisfies nothing, rather than failing the comparison.
#assert.eq(below((other: 1)), false)

#for (op, yes, no) in (("<=", 0.05, 0.06), (">", 0.06, 0.05), (">=", 0.05, 0.04)) {
  let test = resolve-predicate((column: "margin", op: op, value: 0.05))
  assert.eq(test((margin: yes)), true)
  assert.eq(test((margin: no)), false)
}

#let equal = resolve-predicate((column: "region", op: "==", value: "North"))
#assert.eq(equal((region: "North")), true)
#assert.eq(equal((region: "South")), false)

#let unequal = resolve-predicate((column: "region", op: "!=", value: "North"))
#assert.eq(unequal((region: "South")), true)

// --- composition ---

// The keys are quoted because and, or, and not are Typst keywords; that is also
// how json() hands them back.
#let both = resolve-predicate((
  "and": (
    (column: "margin", op: "<", value: 0.05),
    (column: "region", op: "==", value: "North"),
  ),
))
#assert.eq(both((margin: 0.03, region: "North")), true)
#assert.eq(both((margin: 0.03, region: "South")), false)

#let either = resolve-predicate((
  "or": ((column: "units", op: ">", value: 100), (column: "region", op: "==", value: "South")),
))
#assert.eq(either((units: 5, region: "South")), true)
#assert.eq(either((units: 5, region: "North")), false)

#let negated = resolve-predicate(("not": (column: "region", op: "==", value: "North")))
#assert.eq(negated((region: "South")), true)
#assert.eq(negated((region: "North")), false)

// --- a whole specification ---

// This is the shape json() would hand back: no closures anywhere.
#let serialised = (
  kind: "display-table",
  data: (
    (product: "Bolt", region: "North", units: 1250, margin: 0.182),
    (product: "Nut", region: "North", units: 860, margin: 0.031),
  ),
  header: (title: "Regional sales", subtitle: none),
  stub: (rowname: "product", group: "region", label: none, indent: none),
  labels: (units: "Units", margin: "Margin"),
  formats: (
    (name: "format-integer", columns: "units"),
    (name: "format-percent", columns: "margin", decimals: 1),
  ),
  summaries: ((name: "aggregate-sum", label: "Subtotal", columns: ("units",)),),
  styles: ((
    style: (text: (weight: "bold")),
    part: "body",
    columns: "margin",
    rows: (column: "margin", op: "<", value: 0.05),
  ),),
  source-notes: ("Source: internal ledger.",),
)

#let spec = resolve-serialised(serialised, build-spec)

#assert.eq(spec.kind, "display-table")
#assert.eq(spec.columns, ("units", "margin"))
#assert.eq(spec.stub.rowname, "product")
#assert.eq(spec.labels.units, [Units])
#assert.eq(spec.formats.len(), 2)
#assert.eq(spec.summaries.len(), 1)
#assert.eq(spec.styles.len(), 1)
#assert.eq(spec.groups.map(group => group.label), ("North",))

// The formatter came back as a function, and formats as its named version does.
// The default group separator is a thin space, which is what the built-in
// formatter uses whether it was named or called directly.
#assert.eq((spec.formats.first().function)(1250).integer, "1" + sym.space.thin + "250")

// And the whole thing renders through the same pipeline as a hand-built table.
#assert.eq(type(display-table(spec: spec)), content)

// --- the entry point takes the serialised form directly ---

// No resolve-serialised call: display-table recognises data where a built
// specification would have a resolved column list.
#assert.eq(type(display-table(spec: serialised)), content)
