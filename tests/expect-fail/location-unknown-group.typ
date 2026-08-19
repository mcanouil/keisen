// A group label the table does not carry names a group the reader believes is
// there, so it is reported rather than answered with no cells.
// expect: cells-row-groups: unknown group "Nowhere"
// expect: Known groups: "North", "South".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (region: ("North", "South"), units: (1, 2)),
  table-stub(group: "region"),
  table-style(style(fill: aqua), locations: cells-row-groups(groups: "Nowhere")),
)
