// A serialised pattern names its sources by number, counting from 1 in `from`
// order, so a number past the last source names one that is not there.
// expect: columns-combine: pattern names source 3
// expect: got "{1} ({3})".
// expect: Sources count from 1 in from order, and this combine has 2.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((estimate: 1.0, error: 0.1),),
  combines: ((into: "reading", from: ("estimate", "error"), pattern: "{1} ({3})"),),
))
