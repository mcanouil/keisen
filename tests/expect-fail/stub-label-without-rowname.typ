// The stubhead labels the row-name column, so a label with no rowname beneath it
// labels nothing.
// expect: table-stub: label needs a rowname
// expect: A stubhead labels the row-name column, so name one with rowname.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (region: ("N", "S"), units: (5, 3)),
  table-stub(group: "region", label: [Product]),
)
