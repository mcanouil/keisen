// A spanner descriptor with no columns, which used to raise Typst's own
// dictionary-key error instead of naming the part.
// expect: spanner: missing columns

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (kind: "display-table", data: ((units: 1),), spanners: ((label: "Metrics"),)),
  build-spec,
)
