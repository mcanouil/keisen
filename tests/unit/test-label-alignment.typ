// The stubhead and the column labels follow one alignment rule: the theme
// option where it names an alignment, the column's own edge where it leaves the
// choice to the column. The rule was written out at both call sites, and the
// half that reads the option had never run.

#import "../../src/render/layout.typ": label-alignment
#import "../../src/spec.typ": build-spec
#import "../../src/theme/options.typ": DEFAULTS, option, table-options

// Left to the column: the column's edge comes through whatever it is.
#assert.eq(label-alignment(auto, end), end)
#assert.eq(label-alignment(auto, start), start)

// Named by the theme: the option wins over the column's edge, which is the half
// the option exists for.
#assert.eq(label-alignment(center, end), center)
#assert.eq(label-alignment(start, end), start)

// The default leaves it to the column, which is why nothing had taken the other
// half: no test, example or preset had ever set the option.
#assert.eq(DEFAULTS.at("column-labels-align"), auto)

// And as the renderer reads it, through the merged options of a spec.
#let spec = build-spec((units: (1,)), (table-options(column-labels-align: center),), (:))
#assert.eq(label-alignment(option(spec.options, "column-labels-align"), end), center)
