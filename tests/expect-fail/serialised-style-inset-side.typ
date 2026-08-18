// Typst reads an inset per named side, and a side it does not know is no inset
// at all rather than an error, so the side is held to the ones that exist.
// expect: style: unknown key lft
// expect: Known keys: left, right, top, bottom, x, y, rest.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (inset: (lft: "4pt")), part: "body", columns: "units"),),
  ),
  build-spec,
)
