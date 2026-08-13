///! Assembly of the spec into one native table.
///!
///! Nothing is stacked around the table, so its own width governs every part.
///! The title block is a level-1 header, the column labels a level-2 header
///! that repeats across page breaks, and the notes a footer that does not.
///! Every cell is emitted explicitly, which gives one place where fills,
///! alignment, and strokes are decided.

#import "../format/apply.typ": apply-formats
#import "../parts/spanners.typ": spanner-rows
#import "plan.typ": build-plan

// Numeric columns sit against the end edge, everything else against the start
// edge. Direction-relative, because Typst lays cells out along the writing
// direction and reverses column order in right-to-left text.
#let infer-alignment(rows, name) = {
  let values = rows.map(row => row.at(name, default: none)).filter(value => value != none)
  if values.len() == 0 { return start }
  if values.all(value => type(value) in (int, float, decimal)) { end } else { start }
}

// Built-in formatters return the alignment dictionary rather than content, so
// a later milestone can pad the slots to line columns up on their separator.
// Until then the slots are concatenated in reading order.
// Always returns content: a cell holds content, and an unformatted column still
// carries whatever the data had in it.
#let slots-to-content(value) = {
  if value == none { return [] }
  if type(value) == content { return value }
  if type(value) == dictionary and value.at("kind", default: none) == "number" {
    let text = value.sign + value.integer + value.separator + value.fraction
    if value.prefix != none { text = value.prefix + text }
    if value.suffix != none { text = text + value.suffix }
    return [#text]
  }
  [#value]
}

// The stub cell of one body row: its row name, indented by its level.
#let _stub-cell(spec, position) = {
  let row = spec.data.at(position)
  let name = if spec.stub.rowname == none { [] } else {
    slots-to-content(row.at(spec.stub.rowname, default: none))
  }
  let depth = if spec.stub.indent == none { 0 } else { row.at(spec.stub.indent, default: 0) }
  table.cell(align: start, h(1em * depth) + name)
}

#let assemble(spec) = {
  let names = spec.columns
  let has-stub = spec.stub.rowname != none
  let width = calc.max(names.len() + int(has-stub), 1)
  let plan = build-plan(spec)
  let cells = names.map(name => apply-formats(spec.data, spec.formats, name))
  let alignments = names.map(name => infer-alignment(spec.data, name))

  let full(body) = table.cell(colspan: width, body)

  let head = ()
  if spec.header.title != none { head.push(full(strong(spec.header.title))) }
  if spec.header.subtitle != none { head.push(full(spec.header.subtitle)) }

  // Spanner rows sit above the column labels inside the same repeating header,
  // highest level first, with an empty cell over the stub column.
  let labels = ()
  for row in spanner-rows(spec) {
    if has-stub { labels.push(table.cell([])) }
    for cell in row {
      labels.push(table.cell(
        colspan: cell.span,
        align: center,
        if cell.label == none { [] } else { strong(cell.label) },
      ))
    }
  }

  // The stubhead labels the stub column, and is empty unless the stub names it.
  if has-stub {
    let stubhead = if spec.stub.label == none { [] } else { strong(spec.stub.label) }
    labels.push(table.cell(align: start, stubhead))
  }
  for (index, name) in names.enumerate() {
    labels.push(table.cell(
      align: alignments.at(index),
      strong(spec.labels.at(name, default: [#name])),
    ))
  }

  // Group labels are their own headers, so the body is assembled entry by entry
  // rather than as one block of rows.
  let rows = ()
  for entry in plan {
    if entry.part == "group" {
      let label = spec.groups.at(entry.source).label
      rows.push(table.header(level: 3, repeat: true, full(strong([#label]))))
    } else if entry.part == "body" {
      if has-stub { rows.push(_stub-cell(spec, entry.source)) }
      for (index, name) in names.enumerate() {
        rows.push(table.cell(
          align: alignments.at(index),
          slots-to-content(cells.at(index).at(entry.source)),
        ))
      }
    }
  }

  let notes = spec.source-notes.map(note => full(text(size: 0.8em, note)))

  table(
    columns: width,
    stroke: none,
    ..if head.len() > 0 { (table.header(level: 1, repeat: false, ..head),) } else { () },
    ..if labels.len() > 0 { (table.header(level: 2, repeat: true, ..labels),) } else { () },
    ..rows,
    ..if notes.len() > 0 { (table.footer(repeat: false, ..notes),) } else { () },
  )
}
