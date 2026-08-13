///! Public facade for keisen.
///!
///! Every user-facing function is re-exported here.
///! Internal helpers stay `_`-prefixed inside `src/` and are never exported.

#import "src/spec.typ": build-spec
#import "src/render/assemble.typ": assemble
#import "src/theme/presets.typ": theme-default
#import "src/parts/header.typ": table-header
#import "src/parts/stub.typ": table-stub
#import "src/parts/columns.typ": columns-hide, columns-label, columns-move
#import "src/parts/spanners.typ": table-spanner
#import "src/parts/notes.typ": table-source-note
#import "src/format/number.typ": format, format-integer, format-number
#import "src/utils/errors.typ": check, fail-type

// Build a display table from data and any number of directives.
//
// Data and directives arrive through one sink rather than as a required
// positional parameter, so that `display-table(spec: ..)` needs no placeholder
// data: that path is how a generator in another language reaches this pipeline.
#let display-table(..arguments, theme: theme-default(), spec: none) = {
  // A sink swallows named arguments as readily as positional ones, so a
  // misspelled option would vanish without a word.
  let unexpected = arguments.named().keys()
  check(
    unexpected.len() == 0,
    "display-table",
    "unknown argument " + unexpected.join(", "),
    hint: "The named arguments are theme and spec.",
  )

  let resolved = if spec != none {
    check(
      type(spec) == dictionary and spec.at("kind", default: none) == "display-table",
      "display-table",
      "spec is not a display-table specification",
      value: spec,
      hint: "Build it with build-spec, or pass data and directives instead.",
    )
    spec
  } else {
    let positional = arguments.pos()
    check(
      positional.len() > 0,
      "display-table",
      "no data given",
      hint: "Pass data as the first argument, or a built specification as spec.",
    )
    build-spec(positional.first(), positional.slice(1), theme)
  }
  assemble(resolved)
}
