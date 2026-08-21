// A currency symbol is placed by name, and the message names the key the caller
// wrote rather than the axis it sets, since `position` is what a specification
// spells. The list is what `format-currency` takes, not what an alignment holds.
// expect: display-table: position must be one of "start", "end"
// expect: got "middle"

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((price: 1),),
    formats: ((name: "format-currency", columns: "price", position: "middle"),),
  ),
  build-spec,
)
