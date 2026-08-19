// The stub labels the rows rather than carrying quantities beside them, so a
// summary naming one of its columns is told what that column is rather than
// that it does not exist.
// expect: summary-rows: column product is in the stub
// expect: The stub labels the rows; a summary aggregates the columns beside it.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), region: ("N", "S"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  summary-rows(functions: (Total: aggregate-sum), columns: "product"),
)
