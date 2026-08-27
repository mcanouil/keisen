// A quantile is a probability, so it lies between 0 and 1. Above one it read
// past the end of the sorted values and failed as a Typst index error.
// expect: aggregate-quantile: probability must lie between 0 and 1
// expect: got 1.5
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (region: ("N", "N"), product: ("Bolt", "Nut"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  summary-rows(functions: (Upper: aggregate-quantile(1.5)), columns: "units"),
)
