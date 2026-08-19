// A descriptor with no name at all, which is a likelier generator bug than a
// misspelled one.
// expect: format: no name given
// expect: got (columns: "units").
// expect: Name the built-in: (name: "format-number", ..).

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (kind: "display-table", data: ((units: 1),), formats: ((columns: "units"),)),
  build-spec,
)
