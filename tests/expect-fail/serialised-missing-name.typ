// A descriptor with no name at all, which is a likelier generator bug than a
// misspelled one.
// expect: format: no name given

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (kind: "display-table", data: ((units: 1),), formats: ((columns: "units"),)),
  build-spec,
)
