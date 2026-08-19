// A row index outside the data is a typo by definition, as it already is for
// table-row-group. A predicate matching nothing is a different case.
// expect: cells-body: row 9 is not in the data
// expect: Rows are numbered from zero, and this table has 2 of them.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-style(style(fill: aqua), locations: cells-body(rows: 9)),
)
