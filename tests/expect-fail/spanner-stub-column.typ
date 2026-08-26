// The stub labels the rows rather than sitting among the columns, so a spanner
// naming one of its columns is told what that column is rather than that it
// does not exist. Reported as unknown, the reader hunts for a typo that is not
// there.
// expect: table-spanner: column city is in the stub
// expect: A spanner labels the columns beside the stub; the stub is not one of them.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (city: ("Lille", "Lyon"), units: (1, 2), price: (1.5, 2.5)),
  table-stub(rowname: "city"),
  table-spanner([Figures], ("city",)),
)
