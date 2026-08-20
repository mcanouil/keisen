// A header row is built by walking the columns once, and one column carries one
// spanner cell. Two spanners claiming a column at the same level left the later
// one holding it, so the earlier label was lost without a word.
// expect: table-spanner: column price is already covered at level 1
// expect: Spanners on one level cannot overlap; raise the level to nest them.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-spanner([Figures], ("units", "price")),
  table-spanner([Totals], ("price",)),
)
