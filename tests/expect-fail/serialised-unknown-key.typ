// A typo in a top-level key used to be dropped without a word, so the table
// simply came out missing a part.
// expect: display-table: unknown key summarie in the specification

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (kind: "display-table", data: ((units: 1),), summarie: ()),
  build-spec,
)
