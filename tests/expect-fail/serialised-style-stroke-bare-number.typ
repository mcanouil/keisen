// A bare number is a thickness with no unit, which is refused rather than
// given one nobody wrote, exactly as a bare column width is.
// expect: style: a thickness needs a unit; got 2

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (stroke: 2), part: "body", columns: "units"),),
  ),
  build-spec,
)
