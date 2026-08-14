///! Public facade for keisen.
///!
///! Every user-facing function is re-exported here.
///!
///! A wildcard import re-exports every module-level binding, so the helpers
///! this file needs for itself are aliased with a leading underscore. Nothing
///! reaches a user's scope that is not part of the grammar, and
///! tests/unit/test-exports.typ holds the list to that.

#import "src/spec.typ": build-spec as _build-spec
#import "src/render/assemble.typ": assemble as _assemble
#import "src/theme/presets.typ": theme-booktabs, theme-compact, theme-default, theme-minimal
#import "src/theme/options.typ": table-options
#import "src/parts/header.typ": table-header
#import "src/parts/stub.typ": table-stub
#import "src/parts/summaries.typ": (
  aggregate-count, aggregate-max, aggregate-mean, aggregate-median, aggregate-min,
  aggregate-quantile, aggregate-standard-deviation, aggregate-sum, grand-summary-rows, summary-rows,
)
#import "src/parts/columns.typ": columns-align, columns-hide, columns-label, columns-move, columns-width
#import "src/parts/spanners.typ": table-spanner
#import "src/parts/notes.typ": table-footnote, table-source-note
#import "src/parts/substitutions.typ": substitute-missing, substitute-zero
#import "src/parts/colour.typ": data-colour
#import "src/style.typ": style, table-style
#import "src/locations.typ": (
  cells-body, cells-column-labels, cells-column-spanners, cells-row-groups, cells-source-notes,
  cells-stub, cells-stubhead, cells-title,
)
#import "src/format/number.typ": format, format-integer, format-number
#import "src/format/percent.typ": format-percent
#import "src/format/nanoplot.typ": format-nanoplot
#import "src/utils/errors.typ": check as _check

// Build a display table from data and any number of directives.
//
// Data and directives arrive through one sink rather than as a required
// positional parameter, so that `display-table(spec: ..)` needs no placeholder
// data: that path is how a generator in another language reaches this pipeline.
#let display-table(..arguments, theme: theme-default(), spec: none) = {
  // A sink swallows named arguments as readily as positional ones, so a
  // misspelled option would vanish without a word.
  let unexpected = arguments.named().keys()
  _check(
    unexpected.len() == 0,
    "display-table",
    "unknown argument " + unexpected.join(", "),
    hint: "The named arguments are theme and spec.",
  )

  let resolved = if spec != none {
    _check(
      type(spec) == dictionary and spec.at("kind", default: none) == "display-table",
      "display-table",
      "spec is not a display-table specification",
      value: spec,
      hint: "Build it with build-spec, or pass data and directives instead.",
    )
    spec
  } else {
    let positional = arguments.pos()
    _check(
      positional.len() > 0,
      "display-table",
      "no data given",
      hint: "Pass data as the first argument, or a built specification as spec.",
    )
    _build-spec(positional.first(), positional.slice(1), theme)
  }
  _assemble(resolved)
}
