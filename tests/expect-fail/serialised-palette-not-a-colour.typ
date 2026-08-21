// A palette stop that is not a colour. The scope is the directive the key
// resolves into: `colours` becomes `data-colour` and nothing else, so the name
// sends the reader to the page that documents the palette.
// expect: data-colour: palette is not a colour
// expect: got "greenish".
// expect: Write it as a hex string, for example "#08519c".

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    colours: ((palette: "greenish", columns: "units"),),
  ),
  build-spec,
)
