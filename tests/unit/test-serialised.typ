// A specification that survives JSON: formatters and aggregations named rather
// than passed, and predicates written as comparisons rather than closures.

#import "../../lib.typ": display-table
#import "../../src/format/apply.typ": formatter-for
#import "../../src/spec.typ": build-spec
#import "../../src/render/layout.typ": column-cells
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

// The formatter came back as a directive that formats as its named version
// does, resolved against the theme like any other: a named formatter reads
// number-group-separator, which defaults to a thin space.
#assert.eq(
  (formatter-for(spec.formats.first(), spec.options))(1250).integer,
  "1" + sym.space.thin + "250",
)

// And the whole thing renders through the same pipeline as a hand-built table.
#assert.eq(type(display-table(spec: spec)), content)

// --- substitutions and grand summaries, which a generator writes as data ---
//
// Both are resolved by a loop of their own, and both loops could be made to
// produce nothing at all: `examples/table-spec.json` carries the two keys and
// `examples/serialised.typ` only compiles it, so a whole block of a generator's
// output was dropped without a word.

#let blocks = resolve-serialised(
  (
    kind: "display-table",
    data: ((region: "North", units: 1250), (region: "South", units: none)),
    stub: (rowname: none, group: "region", label: none, indent: none),
    substitutions: ((test: "missing", columns: "units", replacement: "n/a"),),
    summaries: ((name: "aggregate-sum", label: "Subtotal", columns: ("units",)),),
    "grand-summaries": ((name: "aggregate-sum", label: "Total", columns: ("units",)),),
  ),
  build-spec,
)

#assert.eq(blocks.substitutions.len(), 1)
#assert.eq(blocks.substitutions.first().test, "missing")
#assert.eq(blocks.substitutions.first().columns, "units")

// The replacement is written as a string and arrives as content, since that is
// what a cell holds.
#assert.eq(blocks.substitutions.first().replacement, [n/a])

// The two summary loops answer for their own key alone, so neither can stand in
// for the other.
#assert.eq(blocks.summaries.len(), 1)
#assert.eq(blocks.summaries.first().scope, "group")
#assert.eq(blocks.summaries.first().functions.keys(), ("Subtotal",))
#assert.eq(blocks.grand-summaries.len(), 1)
#assert.eq(blocks.grand-summaries.first().scope, "grand")
#assert.eq(blocks.grand-summaries.first().functions.keys(), ("Total",))

// A substitution left without a replacement takes the package's own dash rather
// than nothing, which is the value a generator omits the key to get.
#let dashed = resolve-serialised(
  (
    kind: "display-table",
    data: ((units: none),),
    substitutions: ((test: "zero", columns: "units"),),
  ),
  build-spec,
)
#assert.eq(dashed.substitutions.first().test, "zero")
#assert.eq(dashed.substitutions.first().replacement, [--])

// --- significant digits are nameable wherever the formatter takes them ---
//
// `format-percent` and `format-currency` forward `significant` to
// format-number, so a generator names it on either. The key was listed for
// format-number alone, which made the serialised path narrower than the
// directives it resolves to.

#let significant-spec = resolve-serialised(
  (
    kind: "display-table",
    data: ((margin: 0.18234, price: 1234.5),),
    formats: (
      (name: "format-percent", columns: "margin", significant: 2),
      (name: "format-currency", columns: "price", significant: 3),
    ),
  ),
  build-spec,
)

#let written(format, value) = {
  let cell = (formatter-for(format, significant-spec.options))(value)
  cell.integer + cell.separator + cell.fraction
}

#assert.eq(written(significant-spec.formats.first(), 0.18234), "18")
#assert.eq(written(significant-spec.formats.last(), 1234.5), "1" + sym.space.thin + "230")

// --- the entry point takes the serialised form directly ---

// No resolve-serialised call: display-table recognises data where a built
// specification would have a resolved column list.
#assert.eq(type(display-table(spec: serialised)), content)

// --- options sit on top of the theme, rather than replacing it ---

#import "../../src/theme/options.typ": option
#import "../../src/theme/presets.typ": theme-booktabs, theme-default

// The third argument to build-spec is the theme; passing the option set there
// silently dropped every rule the theme carries.
#let themed = resolve-serialised(
  (kind: "display-table", data: ((units: 1),), options: (row-striping: true)),
  build-spec,
  theme: theme-default(),
)
#assert.eq(option(themed.options, "row-striping"), true)
#assert.eq(option(themed.options, "table-border-top"), option(theme-default(), "table-border-top"))

// A caller's theme reaches the serialised path too.
#let booktabs = resolve-serialised(
  (kind: "display-table", data: ((units: 1),)),
  build-spec,
  theme: theme-booktabs(),
)
#assert.eq(option(booktabs.options, "cell-inset"), option(theme-booktabs(), "cell-inset"))

// --- a built specification is marked as such ---

// The entry point used to guess from a "columns" key, which a generator might
// reasonably send.
#assert.eq(spec.built, true)
#assert.eq(serialised.at("built", default: false), false)

// --- serialised row selectors accept what every other selector accepts ---

#assert.eq(resolve-predicate(auto), auto)
#assert.eq(resolve-predicate(1), 1)
#assert.eq(resolve-predicate((0, 2)), (0, 2))

// --- a gap is whatever the package calls missing ---

// An empty string is what a generator writes for NA, and it used to abort the
// compile by reaching the comparison.
#let compare = resolve-predicate((column: "margin", op: "<", value: 0.05))
#assert.eq(compare((margin: 0.03)), true)
#assert.eq(compare((margin: "")), false)
#assert.eq(compare((margin: none)), false)

// --- null asks whether a cell is empty ---

#let empty = resolve-predicate((column: "margin", op: "==", value: none))
#assert.eq(empty((margin: none)), true)
#assert.eq(empty((margin: "")), true)
#assert.eq(empty((margin: 0.03)), false)

#let present = resolve-predicate((column: "margin", op: "!=", value: none))
#assert.eq(present((margin: 0.03)), true)
#assert.eq(present((margin: none)), false)

// --- a spanner is selectable by the label the JSON gave it ---

#let spanned = resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1, revenue: 2),),
    spanners: ((label: "Metrics", columns: ("units", "revenue")),),
    styles: ((style: (fill: red), part: "column-spanners", spanners: ("Metrics",)),),
  ),
  build-spec,
)

#import "../../src/style.typ": build-index
#assert.eq(build-index(spanned).len(), 1)

// --- a single part name is accepted where an array is ---

#let titled = resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    header: (title: "Sales", subtitle: none),
    styles: ((style: (fill: red), part: "title", parts: "title"),),
  ),
  build-spec,
)
#assert.eq(build-index(titled).len(), 1)

// A combine pattern cannot be a closure in JSON, so it arrives as a template
// numbering its sources from one in `from` order.
#let combined = resolve-serialised(
  (
    kind: "display-table",
    data: (estimate: (1.234, -0.567), error: (0.021, 0.043)),
    combines: ((into: "effect", from: ("estimate", "error"), pattern: "{1} ({2})", label: "Effect"),),
    formats: ((name: "format-number", columns: "estimate", decimals: 2),),
  ),
  build-spec,
)
#assert.eq(combined.columns, ("effect",))
#assert.eq(combined.labels.effect, [Effect])

#let cells = column-cells(combined)
#assert(repr(cells.first().first()).contains("1.23"))
#assert(repr(cells.first().first()).contains("0.021"))
