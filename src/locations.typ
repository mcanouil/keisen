///! The location DSL and its expansion to cell addresses.
///!
///! A location names cells by what the data says rather than by where they sit,
///! which is the one thing Typst show rules cannot express: they select by
///! element type in document order, with no view of the row behind the cell.
///!
///! Every location expands against the folded spec into addresses shaped
///! `(part, row, column)`, where `row` is the input row position for body and
///! stub cells, the group position for group labels, the note position for
///! notes, and `none` where the part has one row.

#import "format/apply.typ": matches-column, matches-row, named
#import "parts/stub.typ": stub-column-names
#import "parts/summaries.typ": directives-for, summary-labels
#import "utils/errors.typ": check, check-column, fail

// The vocabulary of addressable parts, named once so the renderer and the
// location DSL cannot drift apart. They were spelled independently as bare
// strings, which is how the renderer came to look up styles for summary rows
// that no location could produce: every lookup missed, and nothing said so.
// Named from here, a part the vocabulary does not have is a compile error.
#let PARTS = (
  title: "title",
  column-spanners: "column-spanners",
  column-labels: "column-labels",
  stubhead: "stubhead",
  row-groups: "row-groups",
  stub: "stub",
  body: "body",
  summary: "summary",
  grand-summary: "grand-summary",
  source-notes: "source-notes",
  footnotes: "footnotes",
)

#let cells-body(columns: auto, rows: auto) = (
  kind: "location",
  part: PARTS.body,
  columns: columns,
  rows: rows,
)

#let cells-stub(rows: auto) = (
  kind: "location",
  part: PARTS.stub,
  rows: rows,
)

#let cells-stubhead() = (kind: "location", part: PARTS.stubhead)

#let cells-row-groups(groups: auto) = (
  kind: "location",
  part: PARTS.row-groups,
  groups: groups,
)

#let cells-column-labels(columns: auto) = (
  kind: "location",
  part: PARTS.column-labels,
  columns: columns,
)

#let cells-column-spanners(spanners: auto) = (
  kind: "location",
  part: PARTS.column-spanners,
  spanners: spanners,
)

// The title block holds two rows, addressed by name rather than by position.
#let TITLE-PARTS = ("title", "subtitle")

#let cells-title(parts: TITLE-PARTS) = (
  kind: "location",
  part: PARTS.title,
  parts: if type(parts) == array { parts } else { (parts,) },
)

#let cells-summary(groups: auto, columns: auto, rows: auto) = (
  kind: "location",
  part: PARTS.summary,
  groups: groups,
  columns: columns,
  rows: rows,
)

#let cells-grand-summary(columns: auto, rows: auto) = (
  kind: "location",
  part: PARTS.grand-summary,
  columns: columns,
  rows: rows,
)

#let cells-source-notes(notes: auto) = (
  kind: "location",
  part: PARTS.source-notes,
  notes: notes,
)

// Row 0 is the first note under the table. The footer prints the marked notes
// before the unmarked ones, each group in the order it was written, so this is
// the row a reader can count off the page rather than the position of the
// directive that made it.
#let cells-footnotes(notes: auto) = (
  kind: "location",
  part: PARTS.footnotes,
  notes: notes,
)

#let _address(part, row: none, column: none) = (part: part, row: row, column: column)

// Group labels are strings, taken from the data; spanner labels are content,
// written by hand. Both are selected by equality, so a selector of either type
// compares against the label as it stands.
#let _matches-label(selector, label) = {
  if selector == auto {
    true
  } else if type(selector) == array {
    selector.any(candidate => _matches-label(candidate, label))
  } else if type(selector) == function {
    selector(label)
  } else if type(label) == str and type(selector) in (int, float) {
    // Group labels are strings even when the column held numbers, so a numeric
    // selector matches the label it obviously means.
    str(selector) == label
  } else {
    selector == label
  }
}

// A summary row answers to the label that names it and to its position within
// the group, because both are how a reader says which row they mean: "the
// subtotal", or "the second one".
#let _matches-summary(selector, position, label) = {
  if selector == auto {
    true
  } else if type(selector) == int {
    position == selector
  } else if type(selector) == str {
    label == selector
  } else if type(selector) == array {
    selector.any(candidate => _matches-summary(candidate, position, label))
  } else if type(selector) == function {
    selector(label)
  } else {
    fail(
      "cells-summary",
      "rows selector is not a summary row",
      value: selector,
      hint: "Give auto, a label, a position, an array of either, or a predicate over the label.",
    )
  }
}

// Every cell of a summary row: the visible columns, and the stub cell that
// carries the row's own label. Without a stub that label sits in the first
// visible column, which is already addressed by name.
//
// `columns: none` is the label cell alone, which is how a note is put on the
// row once rather than on every cell of it.
#let _summary-cells(location, spec, part, key) = {
  if location.columns == none {
    if spec.stub.rowname != none { return (_address(part, row: key),) }
    if spec.columns.len() == 0 { return () }
    return (_address(part, row: key, column: spec.columns.first()),)
  }
  let columns = spec.columns.filter(name => matches-column(location.columns, name))
  let cells = columns.map(name => _address(part, row: key, column: name))
  if spec.stub.rowname != none and location.columns == auto {
    cells.push(_address(part, row: key))
  }
  cells
}

// A column that exists but sits elsewhere is not an unknown column, and saying
// so would send the reader hunting for a typo that is not there. Same order and
// same reasoning as `_check-visible` for columns-move.
#let _check-columns(spec, scope, selector) = {
  for name in named(selector, str) {
    check(
      name not in spec.hidden,
      scope,
      "column " + name + " is hidden",
      hint: "Address a visible column, or drop the columns-hide.",
    )
    check(
      name not in stub-column-names(spec.stub),
      scope,
      "column " + name + " is in the stub",
      hint: "cells-stub() addresses the row names, and cells-stubhead() their label.",
    )
    check-column(spec.columns, scope, name)
  }
}

#let _check-rows(spec, scope, selector) = {
  for position in named(selector, int) {
    check(
      position >= 0 and position < spec.data.len(),
      scope,
      "row " + repr(position) + " is not in the data",
      hint: "Rows are numbered from zero, and this table has "
        + str(spec.data.len())
        + " of them.",
    )
  }
}

#let _check-notes(scope, selector, count) = {
  for position in named(selector, int) {
    check(
      position >= 0 and position < count,
      scope,
      "note " + repr(position) + " is not in the table",
      hint: "Notes are numbered from zero, and this table has " + str(count) + " of them.",
    )
  }
}

// Group and spanner labels are matched rather than compared, because a numeric
// selector names the group label it plainly means and a predicate names none of
// them. Only what the selector spells out is checked.
#let _check-labels(scope, selector, labels, what, render) = {
  if selector == auto or type(selector) == function { return }
  let candidates = if type(selector) == array { selector } else { (selector,) }
  for candidate in candidates {
    if type(candidate) == function { continue }
    check(
      labels.any(label => _matches-label(candidate, label)),
      scope,
      "unknown " + what + " " + repr(candidate),
      hint: if labels.len() == 0 {
        "The table has no " + what + "s."
      } else {
        "Known " + what + "s: " + labels.map(render).join(", ") + "."
      },
    )
  }
}

// A summary row answers to its label and to its position within the group, so a
// selector is checked against every row the summaries produce. `rows` is one
// list of labels per group, and one list for a grand summary.
#let _check-summary-rows(scope, selector, rows) = {
  if selector == auto or type(selector) == function { return }
  let candidates = if type(selector) == array { selector } else { (selector,) }
  let known = rows.flatten().dedup()
  for candidate in candidates {
    if type(candidate) == function { continue }
    check(
      rows.any(labels => labels
        .enumerate()
        .any(((position, label)) => _matches-summary(candidate, position, label))),
      scope,
      "unknown summary row " + repr(candidate),
      hint: if known.len() == 0 {
        "The table has no summary rows."
      } else {
        "Known summary rows: " + known.join(", ") + "."
      },
    )
  }
}

#let _group-labels(spec) = spec.groups.map(group => group.label)

#let _expand-one(location, spec) = {
  let part = location.part

  if part == PARTS.body {
    _check-columns(spec, "cells-body", location.columns)
    _check-rows(spec, "cells-body", location.rows)
    let rows = spec.data.filter(row => matches-row(location.rows, row))
    let columns = spec.columns.filter(name => matches-column(location.columns, name))
    rows.map(row => columns.map(name => _address(PARTS.body, row: row._index, column: name))).flatten()
  } else if part == PARTS.stub {
    _check-rows(spec, "cells-stub", location.rows)
    spec.data
      .filter(row => matches-row(location.rows, row))
      .map(row => _address(PARTS.stub, row: row._index))
  } else if part == PARTS.stubhead {
    (_address(PARTS.stubhead),)
  } else if part == PARTS.row-groups {
    _check-labels("cells-row-groups", location.groups, _group-labels(spec), "group", label => label)
    spec
      .groups
      .enumerate()
      .filter(((index, group)) => _matches-label(location.groups, group.label))
      .map(((index, group)) => _address(PARTS.row-groups, row: index))
  } else if part == PARTS.column-labels {
    _check-columns(spec, "cells-column-labels", location.columns)
    spec.columns
      .filter(name => matches-column(location.columns, name))
      .map(name => _address(PARTS.column-labels, column: name))
  } else if part == PARTS.column-spanners {
    // A spanner has no column of its own, so it is addressed by its label.
    _check-labels(
      "cells-column-spanners",
      location.spanners,
      spec.spanners.map(spanner => spanner.label),
      "spanner",
      repr,
    )
    spec.spanners
      .filter(spanner => _matches-label(location.spanners, spanner.label))
      .map(spanner => _address(PARTS.column-spanners, row: spanner.level, column: spanner.label))
  } else if part == PARTS.summary {
    _check-labels("cells-summary", location.groups, _group-labels(spec), "group", label => label)
    if location.columns != none { _check-columns(spec, "cells-summary", location.columns) }
    _check-summary-rows(
      "cells-summary",
      location.rows,
      spec.groups.map(group => summary-labels(directives-for(spec.summaries, group.label))),
    )
    spec
      .groups
      .enumerate()
      .filter(((index, group)) => _matches-label(location.groups, group.label))
      .map(((index, group)) => summary-labels(directives-for(spec.summaries, group.label))
        .enumerate()
        .filter(((position, label)) => _matches-summary(location.rows, position, label))
        .map(((position, label)) => _summary-cells(
          location,
          spec,
          PARTS.summary,
          (group: index, row: position),
        )))
      .flatten()
  } else if part == PARTS.grand-summary {
    if location.columns != none { _check-columns(spec, "cells-grand-summary", location.columns) }
    _check-summary-rows(
      "cells-grand-summary",
      location.rows,
      (summary-labels(spec.grand-summaries),),
    )
    summary-labels(spec.grand-summaries)
      .enumerate()
      .filter(((position, label)) => _matches-summary(location.rows, position, label))
      .map(((position, label)) => _summary-cells(location, spec, PARTS.grand-summary, position))
      .flatten()
  } else if part == PARTS.title {
    for name in location.parts {
      check(
        name in TITLE-PARTS,
        "cells-title",
        "unknown title part",
        value: name,
        hint: "The title block holds " + TITLE-PARTS.map(repr).join(" and ") + ".",
      )
    }
    location.parts.map(name => _address(PARTS.title, column: name))
  } else if part == PARTS.source-notes {
    _check-notes("cells-source-notes", location.notes, spec.source-notes.len())
    spec.source-notes
      .enumerate()
      .filter(((index, note)) => matches-row(location.notes, (_index: index)))
      .map(((index, note)) => _address(PARTS.source-notes, row: index))
  } else if part == PARTS.footnotes {
    // How many rows the footer prints is settled by mark assignment, which
    // reads every other location to number the marks in reading order. It
    // therefore arrives on the spec rather than being derived here: deriving it
    // would mean numbering the marks from inside the numbering.
    if "footnote-rows" not in spec {
      fail(
        "cells-footnotes",
        "the footnote rows are not addressable yet",
        hint: "A footnote cannot mark a footnote row; style them with table-style instead.",
      )
    }
    _check-notes("cells-footnotes", location.notes, spec.footnote-rows)
    range(spec.footnote-rows)
      .filter(position => matches-row(location.notes, (_index: position)))
      .map(position => _address(PARTS.footnotes, row: position))
  } else {
    fail("locations", "unknown location part", value: part)
  }
}

// Locations may be given singly or as an array, so a directive takes one
// argument either way.
#let expand(locations, spec) = {
  let given = if type(locations) == dictionary { (locations,) } else { locations }
  for location in given {
    if type(location) != dictionary or location.at("kind", default: none) != "location" {
      fail(
        "locations",
        "not a location",
        value: location,
        hint: "Use cells-body(), cells-column-labels(), and the other cells-* functions.",
      )
    }
  }
  given.map(location => _expand-one(location, spec)).flatten()
}
