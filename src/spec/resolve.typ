///! Resolution of directives that depend on the final shape of the table.
///!
///! Most directives record what they are told and are validated once at the
///! end. Column ordering could not: `columns-move` used to resolve its anchor
///! against the column list as it stood mid-fold, so hiding the anchor, or
///! promoting it into the stub, changed whether the move succeeded depending on
///! which line was written first. That contradicts the architecture's claim
///! that directive order is free.
///!
///! Ordering now happens here, once, after every directive has been recorded,
///! so a move sees the columns the table actually has.

#import "../parts/stub.typ": stub-column-names
#import "../utils/errors.typ": check, check-column

// A column that exists but is not in the table is not an unknown column, and
// saying so would send the reader hunting for a typo that is not there.
#let _check-visible(spec, name) = {
  check(
    name not in spec.hidden,
    "columns-move",
    "column " + name + " is hidden",
    hint: "Move a visible column, or drop the columns-hide.",
  )
  check(
    name not in stub-column-names(spec.stub),
    "columns-move",
    "column " + name + " is in the stub",
    hint: "The stub sits on the leading edge; its columns are not reordered.",
  )
  check-column(spec.columns, "columns-move", name)
}

#let apply-moves(spec) = {
  let columns = spec.columns

  for directive in spec.moves {
    let anchor = if directive.before != none { directive.before } else { directive.after }
    check(
      anchor != none,
      "columns-move",
      "no anchor given",
      hint: "Pass before: or after: naming the column to move relative to.",
    )

    for name in directive.columns { _check-visible(spec, name) }
    _check-visible(spec, anchor)
    check(
      anchor not in directive.columns,
      "columns-move",
      "cannot move " + anchor + " relative to itself",
      hint: "Move relative to a column other than the ones being moved.",
    )

    let rest = columns.filter(name => name not in directive.columns)
    let at = rest.position(name => name == anchor)
    let cut = if directive.before != none { at } else { at + 1 }
    columns = rest.slice(0, cut) + directive.columns + rest.slice(cut)
  }

  spec.columns = columns
  spec
}

// --- Serialised specifications -----------------------------------------------
//
// A specification that reaches Typst as data, from `json()` or from a generator
// in another language, cannot carry closures. It therefore names what it wants
// and the names are resolved here.
//
// The subset is deliberately small: comparisons composed with and, or, and not,
// and built-ins named as strings. Anything more expressive belongs in a Typst
// literal specification, which keeps this from drifting into an expression
// language nobody wanted to write.

#import "../format/number.typ": format-integer, format-number
#import "../format/percent.typ": format-percent
#import "../parts/summaries.typ": (
  aggregate-count, aggregate-max, aggregate-mean, aggregate-median, aggregate-min,
  aggregate-standard-deviation, aggregate-sum,
)
#import "../utils/errors.typ": fail, fail-enum

#let FORMATTERS = (
  "format-number": format-number,
  "format-integer": format-integer,
  "format-percent": format-percent,
)

#let AGGREGATIONS = (
  "aggregate-sum": aggregate-sum,
  "aggregate-mean": aggregate-mean,
  "aggregate-median": aggregate-median,
  "aggregate-min": aggregate-min,
  "aggregate-max": aggregate-max,
  "aggregate-count": aggregate-count,
  "aggregate-standard-deviation": aggregate-standard-deviation,
)

#let _compare(op, left, right) = {
  if op == "<" { left < right } else if op == "<=" { left <= right } else if op == ">" {
    left > right
  } else if op == ">=" { left >= right } else if op == "==" { left == right } else if op == "!=" {
    left != right
  } else {
    fail-enum("predicate", "op", op, ("<", "<=", ">", ">=", "==", "!="))
  }
}

// A comparison, or and/or/not over comparisons, as a one-argument predicate.
#let resolve-predicate(descriptor) = {
  if type(descriptor) == function { return descriptor }
  if descriptor == auto { return auto }

  if "and" in descriptor {
    let parts = descriptor.at("and").map(resolve-predicate)
    return row => parts.all(test => test(row))
  }
  if "or" in descriptor {
    let parts = descriptor.at("or").map(resolve-predicate)
    return row => parts.any(test => test(row))
  }
  if "not" in descriptor {
    let inner = resolve-predicate(descriptor.at("not"))
    return row => not inner(row)
  }

  for key in ("column", "op", "value") {
    if key not in descriptor {
      fail(
        "predicate",
        "missing " + key,
        value: descriptor,
        hint: "A comparison is (column: .., op: .., value: ..), composed with and, or, not.",
      )
    }
  }

  row => {
    let value = row.at(descriptor.column, default: none)
    // A value that is not there satisfies nothing, rather than comparing types
    // and failing inside Typst.
    if value == none { false } else { _compare(descriptor.op, value, descriptor.value) }
  }
}

#let _named(table, descriptor, scope) = {
  let name = descriptor.at("name", default: none)
  if name not in table {
    fail(
      scope,
      "unknown name " + repr(name),
      hint: "Known names: " + table.keys().join(", ") + ".",
    )
  }
  table.at(name)
}

// Text arrives as strings, since JSON has no content type.
#let _content(value) = if type(value) == str { [#value] } else { value }

#let _selector(value) = if value == none { auto } else { value }

#let _format(descriptor) = {
  let builder = _named(FORMATTERS, descriptor, "format")
  let options = descriptor
  for key in ("name", "columns", "rows") {
    if key in options { let _ = options.remove(key) }
  }
  builder(
    _selector(descriptor.at("columns", default: auto)),
    rows: resolve-predicate(_selector(descriptor.at("rows", default: auto))),
    ..options,
  )
}

#let _style(descriptor) = (
  kind: "style",
  style: descriptor.at("style", default: (:)),
  locations: (
    kind: "location",
    part: descriptor.at("part", default: "body"),
    columns: _selector(descriptor.at("columns", default: auto)),
    rows: resolve-predicate(_selector(descriptor.at("rows", default: auto))),
    groups: _selector(descriptor.at("groups", default: auto)),
    spanners: _selector(descriptor.at("spanners", default: auto)),
    notes: _selector(descriptor.at("notes", default: auto)),
    parts: descriptor.at("parts", default: ("title", "subtitle")),
  ),
)

#let _summary(descriptor, scope) = (
  kind: "summary",
  scope: scope,
  functions: ((descriptor.at("label", default: "Total")): _named(AGGREGATIONS, descriptor, "summary")),
  columns: _selector(descriptor.at("columns", default: auto)),
  groups: _selector(descriptor.at("groups", default: auto)),
  format: none,
)

// A serialised specification is turned back into ordinary directives and folded
// through the same path as a hand-written table, so the two cannot drift: there
// is one pipeline, entered two ways.
#let resolve-serialised(serialised, build) = {
  let directives = ()

  let header = serialised.at("header", default: (:))
  if header.at("title", default: none) != none or header.at("subtitle", default: none) != none {
    directives.push((
      kind: "header",
      title: _content(header.at("title", default: none)),
      subtitle: _content(header.at("subtitle", default: none)),
    ))
  }

  let stub = serialised.at("stub", default: (:))
  if stub.at("rowname", default: none) != none or stub.at("group", default: none) != none {
    directives.push((
      kind: "stub",
      rowname: stub.at("rowname", default: none),
      group: stub.at("group", default: none),
      label: _content(stub.at("label", default: none)),
      indent: stub.at("indent", default: none),
    ))
  }

  let labels = serialised.at("labels", default: (:))
  if labels.len() > 0 {
    let mapped = (:)
    for (name, label) in labels { mapped.insert(name, _content(label)) }
    directives.push((kind: "labels", labels: mapped))
  }

  let hidden = serialised.at("hidden", default: ())
  if hidden.len() > 0 { directives.push((kind: "hide", columns: hidden)) }

  for spanner in serialised.at("spanners", default: ()) {
    directives.push((
      kind: "spanner",
      label: _content(spanner.at("label")),
      columns: spanner.at("columns"),
      level: spanner.at("level", default: 1),
    ))
  }

  for descriptor in serialised.at("formats", default: ()) { directives.push(_format(descriptor)) }

  for descriptor in serialised.at("substitutions", default: ()) {
    directives.push((
      kind: "substitute",
      test: descriptor.at("test", default: "missing"),
      columns: _selector(descriptor.at("columns", default: auto)),
      rows: resolve-predicate(_selector(descriptor.at("rows", default: auto))),
      replacement: _content(descriptor.at("replacement", default: [--])),
    ))
  }

  for descriptor in serialised.at("summaries", default: ()) {
    directives.push(_summary(descriptor, "group"))
  }
  for descriptor in serialised.at("grand-summaries", default: ()) {
    directives.push(_summary(descriptor, "grand"))
  }

  for descriptor in serialised.at("styles", default: ()) { directives.push(_style(descriptor)) }

  for note in serialised.at("source-notes", default: ()) {
    directives.push((kind: "source-note", note: _content(note)))
  }

  build(
    serialised.at("data", default: ()),
    directives,
    serialised.at("options", default: (:)),
  )
}
