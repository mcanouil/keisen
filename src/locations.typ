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

#import "format/apply.typ": matches-column, matches-row
#import "utils/errors.typ": fail

#let cells-body(columns: auto, rows: auto) = (
  kind: "location",
  part: "body",
  columns: columns,
  rows: rows,
)

#let cells-stub(rows: auto) = (
  kind: "location",
  part: "stub",
  rows: rows,
)

#let cells-stubhead() = (kind: "location", part: "stubhead")

#let cells-row-groups(groups: auto) = (
  kind: "location",
  part: "row-groups",
  groups: groups,
)

#let cells-column-labels(columns: auto) = (
  kind: "location",
  part: "column-labels",
  columns: columns,
)

#let cells-column-spanners(spanners: auto) = (
  kind: "location",
  part: "column-spanners",
  spanners: spanners,
)

// The title block holds two rows, addressed by name rather than by position.
#let cells-title(parts: ("title", "subtitle")) = (
  kind: "location",
  part: "title",
  parts: if type(parts) == array { parts } else { (parts,) },
)

#let cells-source-notes(notes: auto) = (
  kind: "location",
  part: "source-notes",
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

#let _expand-one(location, spec) = {
  let part = location.part

  if part == "body" {
    let rows = spec.data.filter(row => matches-row(location.rows, row))
    let columns = spec.columns.filter(name => matches-column(location.columns, name))
    rows.map(row => columns.map(name => _address("body", row: row._index, column: name))).flatten()
  } else if part == "stub" {
    spec.data
      .filter(row => matches-row(location.rows, row))
      .map(row => _address("stub", row: row._index))
  } else if part == "stubhead" {
    (_address("stubhead"),)
  } else if part == "row-groups" {
    spec
      .groups
      .enumerate()
      .filter(((index, group)) => _matches-label(location.groups, group.label))
      .map(((index, group)) => _address("row-groups", row: index))
  } else if part == "column-labels" {
    spec.columns
      .filter(name => matches-column(location.columns, name))
      .map(name => _address("column-labels", column: name))
  } else if part == "column-spanners" {
    // A spanner has no column of its own, so it is addressed by its label.
    spec.spanners
      .filter(spanner => _matches-label(location.spanners, spanner.label))
      .map(spanner => _address("column-spanners", row: spanner.level, column: spanner.label))
  } else if part == "title" {
    location.parts.map(name => _address("title", column: name))
  } else if part == "source-notes" {
    spec.source-notes
      .enumerate()
      .filter(((index, note)) => matches-row(location.notes, (_index: index)))
      .map(((index, note)) => _address("source-notes", row: index))
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
