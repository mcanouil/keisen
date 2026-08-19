// `summary-rows(format: ..)` takes a formatter function as well as a format
// directive, which is what the design documents. The function form reached a
// field access on a closure and died as a raw Typst message naming neither the
// directive nor the reason.

#import "../../lib.typ": format-integer
#import "../../src/parts/stub.typ": table-stub
#import "../../src/parts/summaries.typ": aggregate-sum, grand-summary-rows, summary-rows, summary-values
#import "../../src/render/layout.typ": summarised
#import "../../src/spec.typ": build-spec

#let data = (product: ("Bolt", "Nut"), region: ("N", "N"), units: (5, 3))

#let written(directive) = {
  let spec = build-spec(data, (table-stub(rowname: "product", group: "region"), directive), (:))
  let entry = summary-values(spec).groups.first().first()
  summarised(spec, entry, "units", none)
}

// A bare formatter function is handed the aggregate, as any formatter is handed
// a value.
#assert.eq(
  written(summary-rows(
    functions: (Total: aggregate-sum),
    columns: "units",
    format: value => [#value units],
  )),
  [#8 units],
)

// The directive form still works, and it is the form that carries options, so
// its output is the formatter's rather than the raw aggregate.
#assert.eq(
  type(written(summary-rows(
    functions: (Total: aggregate-sum),
    columns: "units",
    format: format-integer("units", suffix: [ units]),
  ))),
  content,
)
#assert.eq(
  written(summary-rows(functions: (Total: aggregate-sum), columns: "units", format: none)),
  [8],
)

// The grand summary reads its format the same way, since the two directives
// differ only in what they aggregate over.
#let grand = build-spec(
  data,
  (grand-summary-rows(
    functions: (Total: aggregate-sum),
    columns: "units",
    format: value => [#value in all],
  ),),
  (:),
)
#assert.eq(summarised(grand, summary-values(grand).grand.first(), "units", none), [#8 in all])
