// A group label is the value of the group column, read as a string. A value
// that has no string form failed as a raw Typst error inside the grouping,
// which named neither the column nor the row.
// expect: table-stub: group value in row 0 cannot be a label
// expect: got true.
// expect: A group column holds strings or numbers.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (region: (true, false), units: (1, 2)),
  table-stub(group: "region"),
)
