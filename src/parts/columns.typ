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

// Reordering is recorded here and resolved in src/spec/resolve.typ once every
// directive has landed, so a move reads the same wherever it is written.
#let columns-move(..columns, before: none, after: none) = (
  kind: "move",
  columns: columns.pos(),
  before: before,
  after: after,
)

// Widths are given per column; anything unnamed sizes itself. A fraction is
// resolved by Typst against the table's own width.
#let columns-width(widths) = (
  kind: "width",
  widths: widths,
)

// One column built from several. `pattern` takes one argument per source, in
// `from` order, and receives their formatted content: the combine stage sits
// after formatting, which is what makes `(estimate, error) => [#estimate
// (#error)]` read the way it is written.
//
// The result takes the place of the first of its sources, so it sits where the
// reader was already looking, and the sources are hidden rather than dropped:
// they stay readable by predicates and formatters.
#let columns-combine(into, from, pattern, label: auto, hide-sources: true) = (
  kind: "combine",
  into: into,
  from: from,
  pattern: pattern,
  label: label,
  hide-sources: hide-sources,
)

// Alignment may be direction-relative (start, end) or absolute; the default is
// inferred per column from the data.
#let columns-align(alignment, columns: auto) = (
  kind: "align",
  alignment: alignment,
  columns: columns,
)
