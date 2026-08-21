// A spanner descriptor with no columns, which used to raise Typst's own
// dictionary-key error instead of naming the part.
// expect: spanner: missing columns
// expect: got (label: "Metrics").
// expect: A spanner needs a label and the columns it covers.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (kind: "display-table", data: ((units: 1),), spanners: ((label: "Metrics"),)),
  build-spec,
)
