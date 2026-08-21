// A bare number is a thickness with no unit, which is refused rather than
// given one nobody wrote, exactly as a bare column width is.
// expect: display-table: a thickness needs a unit
// expect: got 2.
// expect: Write it as a string, for example "2cm" or "1fr".

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (stroke: 2), part: "body", columns: "units"),),
  ),
  build-spec,
)
