// A stroke dictionary carries its colour under `paint`, and a string that is
// not a colour is reported against the key that holds it.
// expect: style: stroke paint is not a colour
// expect: got "greenish"
// expect: Write it as a hex string, for example "#08519c".

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (stroke: (paint: "greenish", thickness: "1pt")), part: "body", columns: "units"),),
  ),
  build-spec,
)
