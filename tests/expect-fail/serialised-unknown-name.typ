// A formatter that names something the package does not have.
// expect: format: unknown name "format-money"

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    formats: ((name: "format-money", columns: "units"),),
  ),
  build-spec,
)
