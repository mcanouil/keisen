// The vertical half of the same rule: one name per axis.
// expect: display-table: align names two vertical edges
// expect: got "top + bottom".
// expect: Write one of top, horizon, bottom, optionally added to a horizontal name.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((units: 5),),
  styles: ((style: (align: "top + bottom"), columns: "units"),),
))
