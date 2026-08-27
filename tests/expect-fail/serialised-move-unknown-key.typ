// A moves entry carrying a key it does not read. The scope names the directive
// the key resolves into rather than `move`, which is a Typst built-in and takes
// a reader looking it up to a function about drawing.
// expect: columns-move: unknown key befor
// expect: Known keys: columns, before, after.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1, price: 2),),
    moves: ((columns: "price", befor: "units"),),
  ),
  build-spec,
)
