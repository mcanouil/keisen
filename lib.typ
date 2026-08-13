///! Public facade for keisen.
///!
///! Every user-facing function is re-exported here.
///! Internal helpers stay `_`-prefixed inside `src/` and are never exported.

#import "src/spec.typ": build-spec
#import "src/render/assemble.typ": assemble
#import "src/theme/presets.typ": theme-default
#import "src/parts/header.typ": table-header
#import "src/parts/columns.typ": columns-hide, columns-label
#import "src/parts/notes.typ": table-source-note
#import "src/format/number.typ": format, format-integer, format-number
#import "src/utils/errors.typ": check

// Build a display table from data and any number of directives.
//
// Data and directives arrive through one sink rather than as a required
// positional parameter, so that `display-table(spec: ..)` needs no placeholder
// data: that path is how a generator in another language reaches this pipeline.
#let display-table(..arguments, theme: theme-default(), spec: none) = {
  let resolved = if spec != none {
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
