// JSON has no way to spell rgb(), so a colour arrives as a string. One that is
// not a colour used to fail inside the renderer, pointing at keisen rather than
// at the specification.
// expect: style: fill is not a colour
// expect: got "greenish".
// expect: Write it as a hex string, for example "#08519c".

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (fill: "greenish"), part: "body", columns: "units"),),
  ),
  build-spec,
)
