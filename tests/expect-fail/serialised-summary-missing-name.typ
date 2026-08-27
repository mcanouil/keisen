// A summary descriptor with no name. The scope is the directive the key
// resolves into, and `grand-summaries` resolves into `grand-summary-rows`: the
// two summary keys share a resolver but not a directive.
// expect: grand-summary-rows: no name given
// expect: got (label: "Total", columns: "units").
// expect: Name the built-in: (name: "aggregate-sum", ..).

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    "grand-summaries": ((label: "Total", columns: "units"),),
  ),
  build-spec,
)
