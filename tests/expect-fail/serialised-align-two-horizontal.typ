// A cell places itself on both axes, so a style alignment may name one of each.
// Two horizontal names are a contradiction rather than a sum, and Typst
// reported the sum in its own words.
// expect: display-table: align names two horizontal edges
// expect: got "start + end".
// expect: Write one of start, end, center, left, right, optionally added to a vertical name.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((units: 5),),
  styles: ((style: (align: "start + end"), columns: "units"),),
))
