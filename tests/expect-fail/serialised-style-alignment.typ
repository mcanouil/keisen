// A style alignment is named, as a column alignment is, so a name the package
// does not carry is reported against the names it does. It used to reach the
// renderer as a string and fail there, as a Typst type error pointing into the
// package rather than at the specification.
// expect: display-table: align must be one of "start", "end", "center", "left", "right", "top", "horizon", "bottom"
// expect: got "middle"

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (align: "middle"), part: "body", columns: "units"),),
  ),
  build-spec,
)
