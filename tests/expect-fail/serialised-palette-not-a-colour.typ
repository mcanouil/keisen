// A palette stop that is not a colour. The scope is the directive the key
// resolves into, since `data-colour` reads a hex string and fails this way when
// a Typst caller writes it too.
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
