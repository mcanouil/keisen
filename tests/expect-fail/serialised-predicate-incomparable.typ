// A comparison between a column of numbers and a string has no answer. Typst
// reported it from inside the closure, naming a type rather than the predicate
// the caller wrote, so the two sides are held to being the same kind of thing.
// expect: predicate: cannot compare units with the given value
// expect: got (5, "many").
// expect: The column and the value must be the same kind of thing.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((product: "Bolt", units: 5),),
  styles: ((style: (fill: "#ffcccc"), rows: (column: "units", op: ">", value: "many")),),
))
