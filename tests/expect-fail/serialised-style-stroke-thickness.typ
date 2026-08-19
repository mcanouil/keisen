// A stroke written as a string is a colour when it is spelled as one and a
// thickness otherwise, so a thickness with no unit the package reads is
// reported as a thickness.
// expect: style: not a thickness; got "2px"

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((style: (stroke: "2px"), part: "body", columns: "units"),),
  ),
  build-spec,
)
