// An alignments entry carrying a key it does not read. The scope is the
// directive the key resolves into, so the reader has a name to look up.
// expect: columns-align: unknown key colums
// expect: Known keys: alignment, columns.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    alignments: ((alignment: "end", colums: "units"),),
  ),
  build-spec,
)
