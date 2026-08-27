// A substitution answers to what it replaces, and the subset knows two: an
// empty cell and a zero.
// expect: substitution: test must be one of "missing", "zero"
// expect: got "blank"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((units: 5),),
  substitutions: ((test: "blank", columns: "units"),),
))
