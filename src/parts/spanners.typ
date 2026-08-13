///! Column spanners and their header rows.
///!
///! A spanner labels a run of adjacent columns. Adjacency is a property of the
///! final column order, so it is checked once on the folded spec: a
///! `columns-move` may legally be written after the spanner it rearranges.

#import "../utils/errors.typ": check, check-column

// `level` 1 sits directly above the column labels; higher levels stack above,
// so a spanner can span other spanners.
#let table-spanner(label, columns, level: 1) = (
  kind: "spanner",
  label: label,
  columns: columns,
  level: level,
)

// Column name to its position in the final order, built once so neither
// validation nor rendering has to scan the column list per spanner column.
#let _index-of(columns) = {
  let index = (:)
  for (position, name) in columns.enumerate() { index.insert(name, position) }
  index
}

#let validate-spanners(spec) = {
  let index = _index-of(spec.columns)
  for spanner in spec.spanners {
    for name in spanner.columns { check-column(spec.columns, "table-spanner", name) }
    let positions = spanner.columns.map(name => index.at(name)).sorted()
    check(
      positions.last() - positions.first() == positions.len() - 1,
      "table-spanner",
      "columns " + spanner.columns.join(", ") + " are not adjacent",
      hint: "Reorder them with columns-move so the spanner covers a single run.",
    )
  }
  spec
}

// One row of cells per spanner level, highest level first, each row covering
// every column: a spanner cell for a covered run, an empty cell for a gap.
#let spanner-rows(spec) = {
  if spec.spanners.len() == 0 { return () }

  let levels = spec.spanners.map(spanner => spanner.level).dedup().sorted().rev()
  let width = spec.columns.len()

  levels.map(level => {
    // One dictionary per level rather than a scan per column: a column covered
    // by this level looks its spanner up directly.
    let covering = (:)
    for spanner in spec.spanners.filter(spanner => spanner.level == level) {
      for name in spanner.columns { covering.insert(name, spanner) }
    }

    let cells = ()
    let position = 0
    while position < width {
      let spanner = covering.at(spec.columns.at(position), default: none)
      if spanner == none {
        cells.push((label: none, span: 1))
        position += 1
      } else {
        cells.push((label: spanner.label, span: spanner.columns.len()))
        position += spanner.columns.len()
      }
    }
    cells
  })
}
