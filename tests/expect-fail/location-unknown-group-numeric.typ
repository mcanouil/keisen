// `table-row-group` takes its label as written, so a group can be labelled with
// a number. Listing the known groups in the hint then joined an integer into a
// sentence, and the reader got a raw Typst message about adding a string and an
// integer, pointing into the package's own source.
// expect: cells-row-groups: unknown group 9
// expect: Known groups: 3, 4.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut", "Beam", "Plate"), units: (1, 2, 3, 4)),
  table-stub(rowname: "product"),
  table-row-group(3, (0, 1)),
  table-row-group(4, (2, 3)),
  table-style(style(fill: aqua), locations: cells-row-groups(groups: 9)),
)
