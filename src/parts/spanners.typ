///! Column spanners and their header rows.
///!
///! A spanner labels a run of adjacent columns. Adjacency is a property of the
///! final column order, so it is checked once on the folded spec: a
///! `columns-move` may legally be written after the spanner it rearranges.

#import "../utils/errors.typ": check

// `level` 1 sits directly above the column labels; higher levels stack above,
// so a spanner can span other spanners.
#let table-spanner(label, columns, level: 1) = (
  kind: "spanner",
  label: label,
  columns: columns,
  level: level,
)

// Positions of a spanner's columns in the final order, sorted, so adjacency can
// be read as a contiguous run.
#let _positions(spanner, columns) = {
  spanner.columns.map(name => {
    let position = columns.position(candidate => candidate == name)
    check(
      position != none,
      "table-spanner",
      "unknown column " + name,
      hint: if columns.len() == 0 {
        "The table has no visible columns."
      } else {
        "Visible columns: " + columns.join(", ") + "."
      },
    )
    position
  })
}

#let validate-spanners(spec) = {
  for spanner in spec.spanners {
    let positions = _positions(spanner, spec.columns).sorted()
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

  levels.map(level => {
    let covering = spec.spanners.filter(spanner => spanner.level == level)
    let cells = ()
    let position = 0
    while position < spec.columns.len() {
      let name = spec.columns.at(position)
      let spanner = covering.find(candidate => name in candidate.columns)
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
