///! Directive folding into the display-table spec, and spec validation.
///!
///! Directives are plain dictionaries applied in declaration order, so a
///! generator in another language can build a spec directly rather than
///! emitting markup. Validation runs once on the folded spec rather than inside
///! each directive, which is what makes directive order free.

#import "data.typ": column-names, normalise
#import "parts/spanners.typ": validate-spanners
#import "parts/stub.typ": build-groups, stub-column-names
#import "utils/errors.typ": check, check-column, fail

#let _empty = (
  kind: "display-table",
  data: (),
  // Every column the data carries, rendered or not, so validation can tell an
  // unknown name from a hidden one.
  data-columns: (),
  columns: (),
  hidden: (),
  labels: (:),
  header: (title: none, subtitle: none),
  stub: (rowname: none, group: none, label: none, indent: none),
  groups: (),
  spanners: (),
  formats: (),
  source-notes: (),
  options: (:),
)

#let _validate(spec) = {
  let stub-columns = stub-column-names(spec.stub)
  let known = spec.columns + spec.hidden + stub-columns

  // The stub names data columns, which exist whether or not they are rendered;
  // everything else names columns the table knows about.
  for name in stub-columns { check-column(spec.data-columns, "table-stub", name) }

  // A hidden column that does not exist is a typo, and leaving it unchecked
  // would whitelist the same typo for every other directive.
  for name in spec.hidden { check-column(spec.data-columns, "columns-hide", name) }

  for name in spec.labels.keys() { check-column(known, "columns-label", name) }

  spec
}

#let build-spec(data, directives, theme) = {
  let spec = _empty
  spec.data = normalise(data)
  // A column store names its columns even when it holds no rows, so filtered
  // data still renders its header rather than losing every column.
  spec.data-columns = if type(data) == dictionary and spec.data.len() == 0 {
    data.keys()
  } else {
    column-names(spec.data)
  }
  spec.columns = spec.data-columns
  spec.options = theme

  for directive in directives {
    check(
      type(directive) == dictionary and "kind" in directive,
      "display-table",
      "argument is not a directive",
      value: directive,
      hint: "Pass directives such as table-header() or format-number().",
    )

    if directive.kind == "header" {
      spec.header = (title: directive.title, subtitle: directive.subtitle)
    } else if directive.kind == "stub" {
      spec.stub = directive
      // The stub columns label the table rather than carry data, so they leave
      // the column list while staying in the row store for predicates.
      let promoted = stub-column-names(directive)
      spec.columns = spec.columns.filter(name => name not in promoted)
    } else if directive.kind == "labels" {
      spec.labels = spec.labels + directive.labels
    } else if directive.kind == "hide" {
      spec.hidden = spec.hidden + directive.columns
      spec.columns = spec.columns.filter(name => name not in directive.columns)
    } else if directive.kind == "spanner" {
      spec.spanners.push(directive)
    } else if directive.kind == "move" {
      let rest = spec.columns.filter(name => name not in directive.columns)
      let anchor = if directive.before != none { directive.before } else { directive.after }
      let at = rest.position(name => name == anchor)
      check(
        at != none,
        "columns-move",
        "unknown column " + str(anchor),
        hint: "Move relative to a visible column other than the ones being moved.",
      )
      let cut = if directive.before != none { at } else { at + 1 }
      spec.columns = rest.slice(0, cut) + directive.columns + rest.slice(cut)
    } else if directive.kind == "format" {
      spec.formats.push(directive)
    } else if directive.kind == "source-note" {
      spec.source-notes.push(directive.note)
    } else {
      fail(
        "display-table",
        "unknown directive",
        value: directive.kind,
        hint: "This version handles header, stub, labels, hide, move, spanner, format, and source-note.",
      )
    }
  }

  spec.groups = build-groups(spec.data, spec.stub.group)

  validate-spanners(_validate(spec))
}
