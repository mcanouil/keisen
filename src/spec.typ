///! Directive folding into the display-table spec, and spec validation.
///!
///! Directives are plain dictionaries applied in declaration order, so a
///! generator in another language can build a spec directly rather than
///! emitting markup. Validation runs once on the folded spec rather than inside
///! each directive, which is what makes directive order free.

#import "data.typ": column-names, normalise
#import "utils/errors.typ": check, fail

#let _empty = (
  kind: "display-table",
  data: (),
  columns: (),
  hidden: (),
  labels: (:),
  header: (title: none, subtitle: none),
  formats: (),
  source-notes: (),
  options: (:),
)

#let _validate(spec) = {
  let known = spec.columns + spec.hidden

  // A hidden column that does not exist is a typo, and leaving it unchecked
  // would whitelist the same typo for every other directive.
  for name in spec.hidden {
    check(
      name in known,
      "columns-hide",
      "unknown column " + name,
      hint: "Hide a column the data actually has.",
    )
  }

  for name in spec.labels.keys() {
    check(
      name in known,
      "columns-label",
      "unknown column " + name,
      hint: if known.len() == 0 {
        "The data has no columns."
      } else {
        "Known columns: " + known.join(", ") + "."
      },
    )
  }
  spec
}

#let build-spec(data, directives, theme) = {
  let spec = _empty
  spec.data = normalise(data)
  // A column store names its columns even when it holds no rows, so filtered
  // data still renders its header rather than losing every column.
  spec.columns = if type(data) == dictionary and spec.data.len() == 0 {
    data.keys()
  } else {
    column-names(spec.data)
  }
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
    } else if directive.kind == "labels" {
      spec.labels = spec.labels + directive.labels
    } else if directive.kind == "hide" {
      spec.hidden = spec.hidden + directive.columns
      spec.columns = spec.columns.filter(name => name not in directive.columns)
    } else if directive.kind == "format" {
      spec.formats.push(directive)
    } else if directive.kind == "source-note" {
      spec.source-notes.push(directive.note)
    } else {
      fail(
        "display-table",
        "unknown directive",
        value: directive.kind,
        hint: "This version handles header, labels, hide, format, and source-note.",
      )
    }
  }

  _validate(spec)
}
