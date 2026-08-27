// A declared group needs the rows it claims; a label over nothing is not a
// group, and the descriptor says so rather than folding into an empty one.
// expect: table-row-group: missing rows
// expect: got (label: "Nordics").
// expect: A declared group needs a label and the rows it claims.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: (units: (1, 2)),
  row-groups: ((label: "Nordics",),),
))
