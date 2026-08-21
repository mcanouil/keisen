// A summary descriptor with no name. The scope is the key the caller wrote,
// which no public directive is called, so it stays as written.
// expect: summary: no name given
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
