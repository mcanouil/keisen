// Options are named, and a positional argument names none of them.
// expect: table-options: options are named, not positional
// expect: Write table-options(row-striping: true).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  table-options(true),
)
