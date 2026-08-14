///! Directive folding into the display-table spec, and spec validation.
///!
///! Directives are plain dictionaries applied in declaration order, so a
///! generator in another language can build a spec directly rather than
///! emitting markup. Validation runs once on the folded spec rather than inside
///! each directive, which is what makes directive order free.

#import "data.typ": column-names, group-rows, normalise
#import "parts/spanners.typ": validate-spanners
#import "parts/stub.typ": stub-column-names
#import "format/apply.typ": matches-column, nanoplot-columns
#import "spec/resolve.typ": apply-moves
#import "theme/options.typ": validate-options
#import "utils/errors.typ": check, check-column, fail

#let _empty = (
  kind: "display-table",
  // Set by build-spec alone, so the entry point can tell a resolved
  // specification from one that arrived as data and named its formatters.
  built: true,
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
  moves: (),
  formats: (),
  styles: (),
  substitutions: (),
  colours: (),
  footnotes: (),
  summaries: (),
  grand-summaries: (),
  widths: (:),
  align: (:),
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

  check(
    spec.summaries.len() == 0 or spec.stub.group != none,
    "summary-rows",
    "there are no groups to summarise",
    hint: "Give table-stub a group column, or use grand-summary-rows for the whole body.",
  )

  if spec.stub.indent != none {
    for row in spec.data {
      let depth = row.at(spec.stub.indent, default: 0)
      check(
        type(depth) == int and depth >= 0,
        "table-stub",
        "indent level in row " + str(row._index) + " is not a whole number of steps",
        value: depth,
        hint: "An indent column holds non-negative integers.",
      )
    }
  }

  // A nanoplot column is left out of a summary that takes every column, since
  // series of readings have no total. Naming one is a different thing: it says
  // the reader expected an aggregate that cannot exist, so it is refused rather
  // than answered with a blank cell.
  let plots = nanoplot-columns(spec.formats, spec.columns)
  for directive in spec.summaries + spec.grand-summaries {
    if directive.columns == auto { continue }
    for name in plots.filter(name => matches-column(directive.columns, name)) {
      fail(
        "summary-rows",
        "column " + name + " holds nanoplots and cannot be summarised",
        hint: "Name the other columns: aggregating series of readings has no meaning.",
      )
    }
  }

  for name in spec.labels.keys() { check-column(known, "columns-label", name) }
  for name in spec.widths.keys() { check-column(known, "columns-width", name) }
  for name in spec.align.keys() { check-column(known, "columns-align", name) }

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
  spec.options = validate-options(theme, "display-table")

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
      check(
        spec.stub.rowname == none and spec.stub.group == none,
        "table-stub",
        "the stub is already defined",
        hint: "One table-stub per table; put every stub column in that one call.",
      )
      check(
        directive.rowname != none or directive.label == none,
        "table-stub",
        "label needs a rowname",
        hint: "A stubhead labels the row-name column, so name one with rowname.",
      )
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
      // Recorded rather than applied: ordering resolves once the table knows
      // which columns it has, so a move reads the same wherever it is written.
      spec.moves.push(directive)
    } else if directive.kind == "format" {
      spec.formats.push(directive)
    } else if directive.kind == "style" {
      spec.styles.push(directive)
    } else if directive.kind == "substitute" {
      spec.substitutions.push(directive)
    } else if directive.kind == "colour" {
      spec.colours.push(directive)
    } else if directive.kind == "footnote" {
      spec.footnotes.push(directive)
    } else if directive.kind == "options" {
      spec.options = spec.options + directive.options
    } else if directive.kind == "width" {
      check(
        type(directive.widths) == dictionary,
        "columns-width",
        "widths must map column names to lengths",
        value: directive.widths,
      )
      spec.widths = spec.widths + directive.widths
    } else if directive.kind == "align" {
      // Named columns are recorded as given so an unknown name is reported;
      // a selector matching nothing would otherwise be silent.
      if type(directive.columns) == str {
        spec.align.insert(directive.columns, directive.alignment)
      } else {
        for name in spec.columns.filter(name => matches-column(directive.columns, name)) {
          spec.align.insert(name, directive.alignment)
        }
      }
    } else if directive.kind == "summary" {
      if directive.scope == "group" {
        spec.summaries.push(directive)
      } else {
        spec.grand-summaries.push(directive)
      }
    } else if directive.kind == "source-note" {
      spec.source-notes.push(directive.note)
    } else {
      fail(
        "display-table",
        "unknown directive",
        value: directive.kind,
        hint: "This version handles header, stub, labels, hide, move, spanner, format, style, substitute, colour, footnote, and source-note.",
      )
    }
  }

  // Ordering first, so spanner adjacency and every column check see the order
  // the table will actually render in. Validation then runs once, before
  // grouping, which would otherwise die inside the data layer rather than
  // naming the offending directive.
  let validated = validate-spanners(_validate(apply-moves(spec)))
  validated.groups = group-rows(validated.data, validated.stub.group)
  validated
}
