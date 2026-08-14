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
#import "../parts/substitutions.typ": is-missing
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
    check(
      directive.before == none or directive.after == none,
      "columns-move",
      "before and after cannot both be given",
      hint: "A column goes on one side of the anchor or the other.",
    )
    let anchor = if directive.before != none { directive.before } else { directive.after }
    check(
      anchor != none,
      "columns-move",
      "no anchor given",
      hint: "Pass before: or after: naming the column to move relative to.",
    )
    check(
      directive.columns.dedup().len() == directive.columns.len(),
      "columns-move",
      "the same column is moved twice",
      value: directive.columns,
      hint: "A column appears once in a table.",
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

#let OPERATORS = ("<", "<=", ">", ">=", "==", "!=")

// A comparison, or and/or/not over comparisons, as a one-argument predicate.
// Anything that is already a selector in its own right passes straight through,
// so an index or an array of indices means what it means everywhere else.
#let resolve-predicate(descriptor) = {
  if type(descriptor) != dictionary { return descriptor }

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

  // Reported while resolving, not on the first row: a location matching no rows
  // would otherwise never reach the comparison and never complain.
  if descriptor.op not in OPERATORS {
    fail-enum("predicate", "op", descriptor.op, OPERATORS)
  }

  row => {
    let value = row.at(descriptor.column, default: none)

    // Comparing against null is how the subset asks whether a cell is empty:
    // there would otherwise be no way to write it, and JSON has no other
    // spelling for absence.
    if descriptor.value == none {
      let missing = is-missing(value)
      return if descriptor.op == "==" { missing } else if descriptor.op == "!=" {
        not missing
      } else {
        fail(
          "predicate",
          "null compares only with == and !=",
          value: descriptor.op,
          hint: "Ordering an empty cell has no meaning.",
        )
      }
    }

    // A gap satisfies nothing. It is whatever the package calls missing, not
    // just none: an empty string is what a generator writes for NA.
    if is-missing(value) { return false }

    let numeric = (int, float, decimal)
    let comparable = type(value) == type(descriptor.value) or (
      type(value) in numeric and type(descriptor.value) in numeric
    )
    if not comparable {
      fail(
        "predicate",
        "cannot compare " + descriptor.column + " with the given value",
        value: (value, descriptor.value),
        hint: "The column and the value must be the same kind of thing.",
      )
    }

    _compare(descriptor.op, value, descriptor.value)
  }
}

#let _keys(descriptor, allowed, scope) = {
  for key in descriptor.keys() {
    if key not in allowed {
      fail(
        scope,
        "unknown key " + key,
        hint: "Known keys: " + allowed.join(", ") + ".",
      )
    }
  }
}

#let _named(table, descriptor, scope) = {
  if "name" not in descriptor {
    fail(
      scope,
      "no name given",
      value: descriptor,
      hint: "Name the built-in: (name: \"" + table.keys().first() + "\", ..).",
    )
  }
  let name = descriptor.name
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

// Colours arrive as strings too, since JSON has no way to spell rgb(). A
// string that is not a colour is reported here rather than inside the renderer.
#let _colour(value, key) = {
  if type(value) != str { return value }
  if value.match(regex("^#[0-9A-Fa-f]{3,8}$")) == none {
    fail(
      "style",
      key + " is not a colour",
      value: value,
      hint: "Write it as a hex string, for example \"#08519c\".",
    )
  }
  rgb(value)
}

// The style properties a cell understands, with the colours resolved.
#let _properties(given) = {
  let out = (:)
  for (key, value) in given {
    out.insert(
      key,
      if key == "fill" { _colour(value, "fill") } else if key == "text" and type(value) == dictionary {
        let inner = value
        if "fill" in inner { inner.insert("fill", _colour(inner.fill, "text fill")) }
        inner
      } else { value },
    )
  }
  out
}

#let _selector(value) = if value == none { auto } else { value }

#let FORMAT-OPTIONS = (
  "format-number": (
    "decimals",
    "significant",
    "grouping",
    "group-separator",
    "decimal-separator",
    "scale",
    "sign",
    "rounding",
    "negative-zero",
    "prefix",
    "suffix",
  ),
  "format-integer": ("grouping", "group-separator", "scale", "sign", "prefix", "suffix"),
  "format-percent": ("decimals", "scale", "symbol", "space"),
)

#let _format(descriptor) = {
  let builder = _named(FORMATTERS, descriptor, "format")
  _keys(
    descriptor,
    ("name", "columns", "rows") + FORMAT-OPTIONS.at(descriptor.name),
    "format",
  )
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

#let _style(descriptor) = {
  _keys(
    descriptor,
    ("style", "part", "columns", "rows", "groups", "spanners", "notes", "parts"),
    "style",
  )
  (
  kind: "style",
  style: _properties(descriptor.at("style", default: (:))),
  locations: (
    kind: "location",
    part: descriptor.at("part", default: "body"),
    columns: _selector(descriptor.at("columns", default: auto)),
    rows: resolve-predicate(_selector(descriptor.at("rows", default: auto))),
    groups: _selector(descriptor.at("groups", default: auto)),
    // Spanner labels are content once resolved, so a selector written as a
    // string would never match the label it plainly names.
    spanners: {
      let given = _selector(descriptor.at("spanners", default: auto))
      if given == auto { auto } else if type(given) == array {
        given.map(_content)
      } else { _content(given) }
    },
    notes: _selector(descriptor.at("notes", default: auto)),
    parts: {
      let given = descriptor.at("parts", default: ("title", "subtitle"))
      if type(given) == array { given } else { (given,) }
    },
  ),
  )
}

#let _summary(descriptor, scope) = {
  _keys(descriptor, ("name", "label", "columns", "groups"), "summary")
  (
  kind: "summary",
  scope: scope,
  functions: ((descriptor.at("label", default: "Total")): _named(AGGREGATIONS, descriptor, "summary")),
  columns: _selector(descriptor.at("columns", default: auto)),
  groups: _selector(descriptor.at("groups", default: auto)),
  format: none,
  )
}

#let SERIALISED-KEYS = (
  "kind",
  "data",
  "header",
  "stub",
  "labels",
  "hidden",
  "spanners",
  "formats",
  "substitutions",
  "summaries",
  "grand-summaries",
  "styles",
  "source-notes",
  "options",
)

// A serialised specification is turned back into ordinary directives and folded
// through the same path as a hand-written table, so the two cannot drift: there
// is one pipeline, entered two ways.
#let resolve-serialised(serialised, build, theme: (:)) = {
  for key in serialised.keys() {
    if key not in SERIALISED-KEYS {
      fail(
        "display-table",
        "unknown key " + key + " in the specification",
        hint: "Known keys: " + SERIALISED-KEYS.join(", ") + ".",
      )
    }
  }

  let directives = ()

  let header = serialised.at("header", default: (:))
  _keys(header, ("title", "subtitle"), "header")
  if header.at("title", default: none) != none or header.at("subtitle", default: none) != none {
    directives.push((
      kind: "header",
      title: _content(header.at("title", default: none)),
      subtitle: _content(header.at("subtitle", default: none)),
    ))
  }

  let stub = serialised.at("stub", default: (:))
  _keys(stub, ("rowname", "group", "label", "indent"), "stub")
  if stub.len() > 0 and stub.values().any(value => value != none) {
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
  let hidden = if type(hidden) == str { (hidden,) } else { hidden }
  if hidden.len() > 0 { directives.push((kind: "hide", columns: hidden)) }

  for spanner in serialised.at("spanners", default: ()) {
    _keys(spanner, ("label", "columns", "level"), "spanner")
    for key in ("label", "columns") {
      if key not in spanner {
        fail("spanner", "missing " + key, value: spanner, hint: "A spanner needs a label and the columns it covers.")
      }
    }
    directives.push((
      kind: "spanner",
      label: _content(spanner.label),
      columns: spanner.columns,
      level: spanner.at("level", default: 1),
    ))
  }

  for descriptor in serialised.at("formats", default: ()) { directives.push(_format(descriptor)) }

  for descriptor in serialised.at("substitutions", default: ()) {
    _keys(descriptor, ("test", "columns", "rows", "replacement"), "substitution")
    let test = descriptor.at("test", default: "missing")
    if test not in ("missing", "zero") {
      fail-enum("substitution", "test", test, ("missing", "zero"))
    }
    directives.push((
      kind: "substitute",
      test: test,
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

  // The third argument is the theme, not the option set: passing options there
  // silently replaced the theme, so a serialised table drew none of its rules.
  // Options belong on top of whatever theme the caller asked for.
  build(
    serialised.at("data", default: ()),
    directives,
    theme + serialised.at("options", default: (:)),
  )
}
