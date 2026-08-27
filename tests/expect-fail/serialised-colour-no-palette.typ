// The palette is what the scale samples, so a colours entry without one names
// no colour to give.
// expect: data-colour: no palette given
// expect: got (columns: "units").
// expect: Give one hex string, or an array of them for a gradient.
#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised
#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 5),),
    colours: ((columns: "units"),),
  ),
  build-spec,
)
