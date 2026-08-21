// An aggregation the package does not have, named where a closure cannot be
// written.
// expect: summary: unknown name "aggregate-mode"
// expect: Known names: aggregate-sum, aggregate-mean, aggregate-median, aggregate-min, aggregate-max, aggregate-count, aggregate-standard-deviation.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    "grand-summaries": ((name: "aggregate-mode", columns: "units"),),
  ),
  build-spec,
)
