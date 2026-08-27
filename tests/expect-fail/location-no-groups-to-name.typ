// A group named on a table that declares none. The hint says the table has no
// groups rather than listing the ones it has, since there are none to list.
// expect: cells-row-groups: unknown group "North"
// expect: The table has no groups.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  table-style(style(fill: aqua), locations: cells-row-groups(groups: "North")),
)
