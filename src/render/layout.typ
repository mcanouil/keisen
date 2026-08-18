///! Layout decisions taken before any cell is emitted.
///!
///! Alignment per column, the decimal metrics a column is padded to, and the
///! content a summary cell ends up holding. `assemble.typ` reads these and puts
///! cells together; nothing here knows what a `table.cell` is.

#import "../format/align.typ": align-slots, column-metrics
#import "../format/apply.typ": apply-formats, formatter-for, matches-column
#import "../parts/substitutions.typ": is-missing, is-zero
#import "../theme/options.typ": option

// Directives that cover a whole column rather than picking rows out of it.
//
// This is the one predicate that decides whether a summary row is formatted at
// all, and it is asked three times: once for the metrics a column is padded to,
// once for the cell that padding is applied to, and once for substitutions. The
// first two disagreeing is what put summary cells outside their column's
// metrics, so they ask the same question here rather than each spelling it.
// A cell formatter reads the row it sits in, and a summary row is an aggregate
// with no row behind it, so it covers nothing here: the column falls back to
// whichever plain directive covers it, or to the aggregate itself.
#let covering(directives, name) = {
  directives.filter(directive => (
    matches-column(directive.columns, name)
      and directive.rows == auto
      and not directive.at("cell", default: false)
  ))
}

// Numeric columns sit against the end edge, everything else against the start
// edge. Direction-relative, because Typst lays cells out along the writing
// direction and reverses column order in right-to-left text.
#let infer-alignment(rows, name) = {
  let values = rows.map(row => row.at(name, default: none)).filter(value => value != none)
  if values.len() == 0 { return start }
  if values.all(value => type(value) in (int, float, decimal)) { end } else { start }
}

#let column-alignments(spec) = {
  let infer = option(spec.options, "infer-alignment")
  spec.columns.map(name => spec.align.at(
    name,
    default: if infer { infer-alignment(spec.data, name) } else { start },
  ))
}

// The stub is not in the column list, so it is read by name rather than by
// position. Start is where a row name goes, and nothing is inferred: the stub
// labels the rows rather than carrying data to line up.
//
// A table with no stub has no row-name column, and a dictionary cannot be asked
// for a key of none, so the absence is answered before the lookup.
#let stub-alignment(spec) = {
  if spec.stub.rowname == none { return start }
  spec.align.at(spec.stub.rowname, default: start)
}

// Built-in formatters return the alignment dictionary rather than content, so
// the slots can be padded to line a column up on its separator. Always returns
// content: a cell holds content, and an unformatted column still carries
// whatever the data had in it.
#let slots-to-content(value) = {
  if value == none { return [] }
  if type(value) == content { return value }
  if type(value) == dictionary and value.at("kind", default: none) == "number" {
    let digits = value.integer + value.separator + value.fraction
    // Only the slots that carry something are joined, so a plain number stays
    // one piece of content rather than becoming a sequence padded with empties.
    // Slot order matches align-slots, which puts the sign ahead of the symbol:
    // -€5 is a debt and €-5 is a typo.
    let pieces = if value.prefix == none {
      ([#(value.sign + digits)],)
    } else {
      ([#(value.sign)], [#(value.prefix)], [#digits])
    }
    if value.exponent != none { pieces.push([#(value.exponent)]) }
    if value.suffix != none { pieces.push([#(value.suffix)]) }
    return pieces.join()
  }
  [#value]
}

// The formatted cells of every visible column, in column order.
//
// A combined column has no data of its own: its cells are built by handing the
// pattern the formatted content of its sources. That is why combine sits after
// format in the pipeline, and why a combined column is opaque afterwards: the
// pattern returns content, so there are no slots left to line up on.
#let column-cells(spec) = {
  let formatted(name) = apply-formats(
    spec.data,
    spec.formats,
    name,
    substitutions: spec.substitutions,
    options: spec.options,
  )

  spec.columns.map(name => {
    let combine = spec.combines.filter(directive => directive.into == name)
    if combine.len() == 0 { return formatted(name) }

    // The last directive wins, as everywhere else.
    let directive = combine.last()
    let sources = directive.from.map(formatted)
    range(spec.data.len()).map(position => (directive.pattern)(
      ..sources.map(cells => slots-to-content(cells.at(position))),
    ))
  })
}

// A summary cell formats through the same path as the body cells above it,
// either by its own format or by whichever directive covers the column.
#let summary-slots(spec, entry, name) = {
  let value = entry.values.at(name, default: none)
  if value == none { return none }
  if entry.format != none { return (formatter-for(entry.format, spec.options))(value) }
  let directives = covering(spec.formats, name)
  if directives.len() == 0 {
    value
  } else {
    (formatter-for(directives.last(), spec.options))(value)
  }
}

// The content of one summary cell, padded to its column's metrics.
#let summarised(spec, entry, name, metric) = {
  let value = entry.values.at(name, default: none)

  // A substitution that covers the whole column covers its summary too.
  for directive in covering(spec.substitutions, name) {
    let applies = if directive.test == "missing" { is-missing(value) } else { is-zero(value) }
    if applies { return directive.replacement }
  }

  let slots = summary-slots(spec, entry, name)
  if slots == none { return [] }
  slots-to-content(align-slots(slots, metric))
}

// The widest rendering of each slot per column, measured over the body cells and
// the summary cells together: a subtotal sitting outside its column's metrics is
// a subtotal that does not line up with the rows it totals.
//
// Measuring needs context, which the table body has, and the metrics are taken
// once per column rather than once per cell.
#let metrics(spec, cells, summaries) = {
  if not option(spec.options, "decimal-align") { return spec.columns.map(name => none) }
  let entries = summaries.groups.flatten() + summaries.grand
  spec.columns
    .enumerate()
    .map(((position, name)) => column-metrics(
      cells.at(position) + entries.map(entry => summary-slots(spec, entry, name)).filter(slots => slots != none),
    ))
}
