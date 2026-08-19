// An inset is a length written as a string, as a column width is, so a unit the
// package does not carry is reported here rather than inside the renderer.
// expect: style: not an inset
// expect: got "4px"
// expect: Write a number and one of pt, mm, cm, in, em, fr, %, or "auto".

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (inset: "4px"), part: "body", columns: "units"),),
  ),
  build-spec,
)
