// A footnote prints the text it is given, so an entry without one prints
// nothing and marks a cell for it.
// expect: footnote: no note given
// expect: got (locations: (part: "body")).
// expect: A footnote needs the text it prints.
#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised
#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 5),),
    footnotes: ((locations: (part: "body"),),),
  ),
  build-spec,
)
