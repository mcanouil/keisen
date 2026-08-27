// An alignments entry that names the columns but not the alignment, which is
// the one key it exists to carry.
// expect: columns-align: no alignment named
// expect: got (columns: "units").
// expect: Name one of start, end, center, left, right.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    alignments: ((columns: "units"),),
  ),
  build-spec,
)
