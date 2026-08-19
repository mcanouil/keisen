// Groups come from the data or from the document, never from both. Two sources
// would need a rule for which one wins, and a rule nobody wrote down is the one
// every reader gets wrong.
// expect: table-row-group: the groups already come from a column
// expect: Drop the group column from table-stub, or drop the table-row-group calls.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (country: ("Denmark", "Spain"), region: ("North", "South"), units: (1, 2)),
  table-stub(rowname: "country", group: "region"),
  table-row-group([Nordics], 0),
)
