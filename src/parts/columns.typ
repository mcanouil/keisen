///! Column labels, order, and visibility.

// Named arguments read as the columns they label: columns-label(mass: [Mass]).
#let columns-label(..pairs) = (
  kind: "labels",
  labels: pairs.named(),
)

// Hidden columns leave the rendered table but stay in the data, so predicates
// and formatters can still read them.
#let columns-hide(..columns) = (
  kind: "hide",
  columns: columns.pos(),
)

// Reordering is resolved against the column list as it stands when the spec is
// folded, so directives may be written in any order.
#let columns-move(columns, before: none, after: none) = (
  kind: "move",
  columns: if type(columns) == array { columns } else { (columns,) },
  before: before,
  after: after,
)
