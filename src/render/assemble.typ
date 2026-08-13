///! Assembly of the spec into one native table.
///!
///! Nothing is stacked around the table, so its own width governs every part.
///! The title block is a level-1 header, the column labels a level-2 header
///! that repeats across page breaks, and the notes a footer that does not.
///! Every cell is emitted explicitly, which gives one place where fills,
///! alignment, and strokes are decided.

#import "../format/apply.typ": apply-formats, matches-column
#import "../data.typ": column
#import "../parts/colour.typ": colour-styles
#import "../parts/marks.typ": assign-marks, marks-for
#import "../parts/spanners.typ": spanner-rows
#import "../style.typ": build-index, style-for
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

#let _cell(properties, body, align: none, colspan: 1) = {
  table.cell(
    colspan: colspan,
    align: properties.at("align", default: align),
    fill: properties.at("fill", default: none),
    inset: properties.at("inset", default: auto),
    stroke: properties.at("stroke", default: none),
    if "text" in properties { text(..properties.text, body) } else { body },
  )
}

// A mark rides above the value, after any substitution, so it survives whatever
// the cell turned out to be.
#let _marked(body, marks) = {
  if marks.len() == 0 { return body }
  body + super(marks.join([,]))
}

#let assemble(spec) = {
  let names = spec.columns
  let has-stub = spec.stub.rowname != none
  let width = calc.max(names.len() + int(has-stub), 1)
  let plan = build-plan(spec)
  let indices = range(names.len())
  let cells = names.map(name => apply-formats(
    spec.data,
    spec.formats,
    name,
    substitutions: spec.substitutions,
  ))
  let footnotes = assign-marks(spec)

  // Data-driven colour resolves per column and merges under explicit styling,
  // so table-style always wins over a gradient.
  let index = spec.colours.fold(build-index(spec), (index, directive) => {
    let out = index
    for name in spec.columns.filter(name => matches-column(directive.columns, name)) {
      for (position, properties) in colour-styles(directive, spec.data, name) {
        let key = "body|" + position + "|" + repr(name)
        out.insert(key, properties + out.at(key, default: (:)))
      }
    }
    out
  })
  let alignments = names.map(name => infer-alignment(spec.data, name))
  let levels = spanner-rows(spec)

  // The stub goes through the same formatting pipeline as every other column,
  // so a format directive naming the row-name column takes effect there too.
  let stub-cells = if has-stub {
    apply-formats(spec.data, spec.formats, spec.stub.rowname, substitutions: spec.substitutions)
  } else { () }
  let indents = if spec.stub.indent == none { () } else {
    column(spec.data, spec.stub.indent)
  }

  let full(body) = table.cell(colspan: width, body)

  let titled(name, body) = full(_marked(
    body,
    marks-for(footnotes, "title", none, name),
  ))

  let head = ()
  if spec.header.title != none { head.push(titled("title", strong(spec.header.title))) }
  if spec.header.subtitle != none { head.push(titled("subtitle", spec.header.subtitle)) }

  // Spanner rows sit above the column labels inside the same repeating header,
  // highest level first, with an empty cell over the stub column. The plan says
  // how many there are and in which order.
  let labels = ()
  for entry in plan.filter(entry => entry.part == "spanner") {
    if has-stub { labels.push(table.cell([])) }
    for cell in levels.at(entry.source) {
      let body = if cell.label == none { [] } else {
        _marked(
          strong(cell.label),
          marks-for(footnotes, "column-spanners", entry.source + 1, cell.label),
        )
      }
      labels.push(table.cell(colspan: cell.span, align: center, body))
    }
  }

  // The stubhead labels the stub column, and is empty unless the stub names it.
  if has-stub {
    // Either spelling labels the stub: the stub's own label, or a columns-label
    // naming the row-name column.
    let label = if spec.stub.label != none {
      spec.stub.label
    } else {
      spec.labels.at(spec.stub.rowname, default: none)
    }
    let stubhead = if label == none { [] } else { strong(label) }
    labels.push(_cell(
      style-for(index, "stubhead", none, none),
      _marked(stubhead, marks-for(footnotes, "stubhead", none, none)),
      align: start,
    ))
  }
  for (position, name) in names.enumerate() {
    labels.push(_cell(
      style-for(index, "column-labels", none, name),
      _marked(
        strong(spec.labels.at(name, default: [#name])),
        marks-for(footnotes, "column-labels", none, name),
      ),
      align: alignments.at(position),
    ))
  }

  // Group labels are their own headers, so the body is assembled entry by entry
  // rather than as one block of rows.
  let rows = ()
  for entry in plan {
    if entry.part == "group" {
      let label = spec.groups.at(entry.source).label
      rows.push(table.header(
        level: entry.level,
        repeat: true,
        _cell(
          style-for(index, "row-groups", entry.source, none),
          _marked(strong([#label]), marks-for(footnotes, "row-groups", entry.source, none)),
          align: start,
          colspan: width,
        ),
      ))
    } else if entry.part == "body" {
      if has-stub {
        let depth = if indents.len() == 0 { 0 } else {
          let level = indents.at(entry.source)
          if level == none { 0 } else { level }
        }
        let name = slots-to-content(stub-cells.at(entry.source))
        let body = if depth == 0 { name } else { h(1em * depth) + name }
        rows.push(_cell(
          style-for(index, "stub", entry.source, none),
          _marked(body, marks-for(footnotes, "stub", entry.source, none)),
          align: start,
        ))
      }
      for position in indices {
        let name = names.at(position)
        rows.push(_cell(
          style-for(index, "body", entry.source, name),
          _marked(
            slots-to-content(cells.at(position).at(entry.source)),
            marks-for(footnotes, "body", entry.source, name),
          ),
          align: alignments.at(position),
        ))
      }
    }
  }

  let notes = ()
  for (position, note) in spec.source-notes.enumerate() {
    notes.push(full(text(
      size: 0.8em,
      _marked(note, marks-for(footnotes, "source-notes", position, none)),
    )))
  }
  // Marked notes print under the source notes, each behind its own mark.
  for footnote in footnotes.filter(footnote => footnote.mark != none) {
    notes.push(full(text(size: 0.8em, super(footnote.mark) + footnote.note)))
  }
  for footnote in footnotes.filter(footnote => footnote.mark == none) {
    notes.push(full(text(size: 0.8em, footnote.note)))
  }

  table(
    columns: width,
    stroke: none,
    ..if head.len() > 0 { (table.header(level: 1, repeat: false, ..head),) } else { () },
    ..if labels.len() > 0 { (table.header(level: 2, repeat: true, ..labels),) } else { () },
    ..rows,
    ..if notes.len() > 0 { (table.footer(repeat: false, ..notes),) } else { () },
  )
}
