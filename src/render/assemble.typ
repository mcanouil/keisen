///! Assembly of the spec into one native table.
///!
///! Nothing is stacked around the table, so its own width governs every part.
///! The title block is a level-1 header, the column labels a level-2 header
///! that repeats across page breaks, and the notes a footer that does not.
///! Every cell is emitted explicitly, which gives one place where fills,
///! alignment, and strokes are decided.

#import "../format/align.typ": align-slots, column-metrics
#import "../format/apply.typ": apply-formats, matches-column
#import "../data.typ": column
#import "../parts/colour.typ": colour-styles
#import "../parts/marks.typ": assign-marks, marks-for
#import "../parts/spanners.typ": spanner-rows
#import "../parts/substitutions.typ": is-missing, is-zero
#import "../parts/summaries.typ": summary-values
#import "../style.typ": build-index, style-for
#import "../theme/options.typ": option
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

// `fill` and `stroke` arrive from the theme and the row plan; an explicit style
// overrides either, which is why the style dictionary is read last.
#let _cell(properties, body, align: auto, colspan: 1, fill: none, stroke: none) = {
  table.cell(
    colspan: colspan,
    align: properties.at("align", default: align),
    fill: properties.at("fill", default: fill),
    inset: properties.at("inset", default: auto),
    stroke: properties.at("stroke", default: stroke),
    if "text" in properties { text(..properties.text, body) } else { body },
  )
}

// A mark rides above the value, after any substitution, so it survives whatever
// the cell turned out to be.
#let _marked(body, marks) = {
  if marks.len() == 0 { return body }
  body + super(marks.join([,]))
}

#let assemble(spec) = context {
  let setting(name) = option(spec.options, name)
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
  let summaries = summary-values(spec)

  // The stub goes through the same formatting pipeline as every other column,
  // so a format directive naming the row-name column takes effect there too.
  let stub-cells = if has-stub {
    apply-formats(spec.data, spec.formats, spec.stub.rowname, substitutions: spec.substitutions)
  } else { () }
  let indents = if spec.stub.indent == none { () } else {
    column(spec.data, spec.stub.indent)
  }

  let full(body) = table.cell(colspan: width, body)

  // Data-driven colour resolves per column and merges under explicit styling,
  // so table-style always wins over a gradient.
  let index = spec.colours.fold(build-index(spec), (index, directive) => {
    let out = index
    for name in spec.columns.filter(name => matches-column(directive.columns, name)) {
      for (position, properties) in colour-styles(directive, spec.data, name) {
        let key = "body|" + position + "|" + repr(name)
        let explicit = out.at(key, default: (:))
        // Deep-merge the text dictionary: a shallow merge would replace it
        // wholesale and take the contrast fill with it, leaving black on black.
        let merged = properties + explicit
        if "text" in properties and "text" in explicit {
          merged.insert("text", properties.text + explicit.text)
        }
        out.insert(key, merged)
      }
    }
    out
  })
  let alignments = names.map(name => spec.align.at(
    name,
    default: if setting("infer-alignment") { infer-alignment(spec.data, name) } else { start },
  ))
  // Measuring needs context, which the table body has; the metrics are computed
  // once per column rather than once per cell.
  let summary-slots(name) = {
    let covering = spec.formats.filter(directive => (
      matches-column(directive.columns, name) and directive.rows == auto
    ))
    let format-one(entry) = {
      let value = entry.values.at(name, default: none)
      if value == none { return none }
      if entry.format != none { return (entry.format.function)(value) }
      if covering.len() == 0 { return value }
      (covering.last().function)(value)
    }
    let entries = summaries.groups.flatten() + summaries.grand
    entries.map(format-one).filter(slots => slots != none)
  }

  let metrics = if spec.options.at("decimal-align", default: true) {
    names.enumerate().map(((position, name)) => column-metrics(cells.at(position) + summary-slots(name)))
  } else {
    names.map(name => none)
  }
  let levels = spanner-rows(spec)

  // A summary cell formats through the same path as the body cells above it,
  // either by its own format or by whichever directive covers the column.
  let summarised(entry, name, metric) = {
    let value = entry.values.at(name, default: none)

    // A substitution that covers the whole column covers its summary too.
    let replacing = spec.substitutions.filter(directive => (
      matches-column(directive.columns, name) and directive.rows == auto
    ))
    for directive in replacing {
      let applies = if directive.test == "missing" { is-missing(value) } else { is-zero(value) }
      if applies { return directive.replacement }
    }

    if value == none { return [] }

    let slots = if entry.format != none {
      (entry.format.function)(value)
    } else {
      // Only directives covering the whole column apply: one aimed at a row has
      // no summary row to aim at.
      let covering = spec.formats.filter(directive => (
        matches-column(directive.columns, name) and directive.rows == auto
      ))
      if covering.len() == 0 { value } else { (covering.last().function)(value) }
    }
    slots-to-content(align-slots(slots, metric))
  }

  let top-border(part) = {
    if part == "group" { setting("row-group-border-top") }
    else if part == "summary" { setting("summary-border-top") }
    else if part == "grand-summary" { setting("grand-summary-border-top") }
    else { none }
  }

  let stripe-fill(entry) = {
    if entry.part != "body" { return none }
    if not setting("row-striping") { return none }
    if entry.stripe { setting("row-striping-fill") } else { none }
  }

  let summary-row(entry, part, row-key) = {
    let cells = ()
    let rule = (top: top-border(part))
    if has-stub {
      cells.push(_cell(
        style-for(index, part, row-key, none),
        text(weight: setting("summary-weight"), [#entry.label]),
        align: start,
        fill: setting("summary-fill"),
        stroke: rule,
      ))
    }
    for (position, name) in names.enumerate() {
      cells.push(_cell(
        style-for(index, part, row-key, name),
        summarised(entry, name, metrics.at(position)),
        align: alignments.at(position),
        fill: setting("summary-fill"),
        stroke: rule,
      ))
    }
    cells
  }

  let titled(name, body, stroke: none) = _cell(
    style-for(index, "title", none, name),
    _marked(body, marks-for(footnotes, "title", none, name)),
    colspan: width,
    stroke: stroke,
  )

  let outer-top = setting("table-border-top")
  let outer-bottom = setting("table-border-bottom")

  let head = ()
  if spec.header.title != none {
    head.push(titled(
      "title",
      text(size: setting("header-title-size"), weight: setting("header-title-weight"), spec.header.title),
      stroke: (top: outer-top),
    ))
  }
  if spec.header.subtitle != none {
    head.push(titled(
      "subtitle",
      text(size: setting("header-subtitle-size"), spec.header.subtitle),
      stroke: (
        top: if spec.header.title == none { outer-top } else { none },
        bottom: setting("header-border-bottom"),
      ),
    ))
  }

  // Spanner rows sit above the column labels inside the same repeating header,
  // highest level first, with an empty cell over the stub column. The plan says
  // how many there are and in which order.
  let labels = ()
  for entry in plan.filter(entry => entry.part == "spanner") {
    if has-stub { labels.push(table.cell([])) }
    let row = levels.at(entry.source)
    for cell in row.cells {
      let body = if cell.label == none { [] } else {
        _marked(
          strong(cell.label),
          marks-for(footnotes, "column-spanners", row.level, cell.label),
        )
      }
      labels.push(_cell(
        style-for(index, "column-spanners", row.level, cell.label),
        body,
        align: center,
        colspan: cell.span,
        stroke: (
          bottom: setting("spanner-border-bottom"),
          top: if head.len() == 0 and entry.source == 0 { outer-top } else { none },
        ),
      ))
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
        text(weight: setting("column-labels-weight"), size: setting("column-labels-size"), spec.labels.at(name, default: [#name])),
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
          _marked(
            text(weight: setting("row-group-weight"), [#label]),
            marks-for(footnotes, "row-groups", entry.source, none),
          ),
          align: start,
          colspan: width,
          fill: setting("row-group-fill"),
          stroke: (top: top-border("group")),
        ),
      ))
    } else if entry.part == "summary" {
      let group = summaries.groups.at(entry.source.group)
      rows += summary-row(group.at(entry.source.row), "summary", entry.source)
    } else if entry.part == "grand-summary" {
      // Wrapped in a non-repeating header of the same level as a group label, so
      // the last group's label is retired: a repeated "South" above the grand
      // total would say the total belongs to South.
      rows.push(table.header(
        level: 3,
        repeat: false,
        ..summary-row(summaries.grand.at(entry.source), "grand-summary", entry.source),
      ))
    } else if entry.part == "body" {
      if has-stub {
        let depth = if indents.len() == 0 { 0 } else {
          let level = indents.at(entry.source)
          if level == none { 0 } else { level }
        }
        let name = slots-to-content(stub-cells.at(entry.source))
        let body = if depth == 0 { name } else { h(setting("stub-indent-step") * depth) + name }
        rows.push(_cell(
          style-for(index, "stub", entry.source, none),
          _marked(body, marks-for(footnotes, "stub", entry.source, none)),
          align: start,
          fill: stripe-fill(entry),
        ))
      }
      for position in indices {
        let name = names.at(position)
        let properties = style-for(index, "body", entry.source, name)
        // Padding measured in the surrounding text style would be wrong under a
        // style that changes the text, and a too-narrow box wraps the number.
        let metric = if "text" in properties { none } else { metrics.at(position) }
        rows.push(_cell(
          properties,
          _marked(
            slots-to-content(align-slots(cells.at(position).at(entry.source), metric)),
            marks-for(footnotes, "body", entry.source, name),
          ),
          align: alignments.at(position),
          fill: stripe-fill(entry),
        ))
      }
    }
  }

  let notes = ()
  for (position, note) in spec.source-notes.enumerate() {
    notes.push(_cell(
      style-for(index, "source-notes", position, none),
      text(size: setting("source-note-size"), _marked(note, marks-for(footnotes, "source-notes", position, none))),
      colspan: width,
      stroke: (
        top: if position == 0 { setting("footer-border-top") } else { none },
        bottom: if position == spec.source-notes.len() - 1 and footnotes.len() == 0 {
          outer-bottom
        } else { none },
      ),
    ))
  }
  // Marked notes print under the source notes, each behind its own mark.
  let marked = footnotes.filter(footnote => footnote.mark != none)
  for footnote in marked {
    notes.push(_cell(
      (:),
      text(size: setting("footnote-size"), super(footnote.mark) + footnote.note),
      colspan: width,
      stroke: (bottom: if footnote == marked.last() { outer-bottom } else { none }),
    ))
  }
  for footnote in footnotes.filter(footnote => footnote.mark == none) {
    notes.push(full(text(size: setting("footnote-size"), footnote.note)))
  }

  // A named width wins; everything else sizes itself, including the stub.
  let tracks = if has-stub { (spec.widths.at(spec.stub.rowname, default: auto),) } else { () }
  for name in names { tracks.push(spec.widths.at(name, default: auto)) }

  // Part borders are read off the row plan: the plan already knows which row
  // opens the body, closes a group, or begins the footer.

  set text(
    ..if setting("table-font") == none { (:) } else { (font: setting("table-font")) },
    ..if setting("table-font-size") == none { (:) } else { (size: setting("table-font-size")) },
  )

  // A table that must stay whole is wrapped rather than left to the page: an
  // unbreakable block is the only thing that stops Typst splitting rows.
  let wrap(body) = if setting("breakable") { body } else { block(breakable: false, body) }

  wrap(table(
    columns: tracks,
    inset: setting("cell-inset"),
    align: setting("table-align"),
    stroke: none,
    ..if head.len() > 0 {
      (table.header(level: 1, repeat: false, ..head),)
    } else { () },
    ..if labels.len() > 0 { (table.header(level: 2, repeat: true, ..labels),) } else { () },
    ..rows,
    ..if notes.len() > 0 { (table.footer(repeat: false, ..notes),) } else { () },
  ))
}
