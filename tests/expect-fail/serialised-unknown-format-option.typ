// An option the built-in does not take, which used to surface as Typst's own
// unexpected-argument error pointing inside keisen.
// expect: format: unknown key digits

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    formats: ((name: "format-number", columns: "units", digits: 2),),
  ),
  build-spec,
)
