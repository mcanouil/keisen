// An alignment is a Typst value, so a serialised one names itself from a fixed
// vocabulary rather than arriving as any string at all.
// expect: align: alignment must be one of "start", "end", "center", "left", "right"
// expect: got "middle"
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: (units: (1, 2)),
  alignments: ((alignment: "middle", columns: "units"),),
))
