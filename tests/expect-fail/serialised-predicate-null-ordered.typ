// Comparing against null is how the subset asks whether a cell is empty, and it
// answers to equality alone: ordering an empty cell has no meaning.
// expect: predicate: null compares only with == and !=
// expect: got ">".
// expect: Ordering an empty cell has no meaning.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((product: "Bolt", units: 5),),
  styles: ((style: (fill: "#ffcccc"), rows: (column: "units", op: ">", value: none)),),
))
