///! Assembly of the spec into one native table.
///!
///! Nothing is stacked around the table, so its own width governs every part.
///! The title block is a level-1 header, the column labels a level-2 header
///! that repeats across page breaks, and the notes a footer that does not.
///! Every cell is emitted explicitly, which gives one place where fills,
///! alignment, and strokes are decided.

#import "../format/apply.typ": apply-formats
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

#let assemble(spec) = {
  let names = spec.columns
  let width = calc.max(names.len(), 1)
  let plan = build-plan(spec)
  let cells = names.map(name => apply-formats(spec.data, spec.formats, name))
  let alignments = names.map(name => infer-alignment(spec.data, name))

  let full(body) = table.cell(colspan: width, body)

  let head = ()
  if spec.header.title != none { head.push(full(strong(spec.header.title))) }
  if spec.header.subtitle != none { head.push(full(spec.header.subtitle)) }

  let labels = names
    .enumerate()
    .map(((index, name)) => table.cell(
      align: alignments.at(index),
      strong(spec.labels.at(name, default: [#name])),
    ))

  let body = ()
  for entry in plan.filter(entry => entry.part == "body") {
    for (index, name) in names.enumerate() {
      body.push(table.cell(
        align: alignments.at(index),
        slots-to-content(cells.at(index).at(entry.source)),
      ))
    }
  }

  let notes = spec.source-notes.map(note => full(text(size: 0.8em, note)))

  table(
    columns: width,
    stroke: none,
    ..if head.len() > 0 { (table.header(level: 1, repeat: false, ..head),) } else { () },
    ..if labels.len() > 0 { (table.header(level: 2, repeat: true, ..labels),) } else { () },
    ..body,
    ..if notes.len() > 0 { (table.footer(repeat: false, ..notes),) } else { () },
  )
}
