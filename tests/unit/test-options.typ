// Options are validated, merged in call order, and read through one door that
// always yields a value.

#import "../../src/spec.typ": build-spec
#import "../../src/theme/options.typ": DEFAULTS, option, table-options, validate-options
#import "../../src/theme/presets.typ": theme-booktabs, theme-compact, theme-default, theme-minimal

// --- the directive ---

#let directive = table-options(row-striping: true)
#assert.eq(directive.kind, "options")
#assert.eq(directive.options, (row-striping: true))

// --- reading ---

// An unset option falls back to its default, so no renderer carries its own.
#assert.eq(option((:), "cell-inset"), DEFAULTS.at("cell-inset"))
#assert.eq(option((cell-inset: 1em), "cell-inset"), 1em)

// --- presets are option dictionaries, and every key they set is known ---

#for preset in (theme-default, theme-booktabs, theme-compact, theme-minimal) {
  let options = preset()
  assert.eq(type(options), dictionary)
  assert.eq(validate-options(options, "test"), options)
}

// theme-compact builds on the default rather than restating it.
#assert.eq(option(theme-compact(), "cell-inset"), 0.3em)
#assert(
  option(theme-compact(), "table-font-size") != option(theme-default(), "table-font-size"),
  message: "theme-compact sets a font size of its own",
)
#assert.eq(option(theme-compact(), "table-border-top"), option(theme-default(), "table-border-top"))

// theme-booktabs is the three-line rule: one above the table, one below it, one
// under the column labels, and nothing under the footer where the default rules.
#assert(option(theme-booktabs(), "table-border-top") != none, message: "booktabs rules the top")
#assert(option(theme-booktabs(), "table-border-bottom") != none, message: "booktabs rules the bottom")
#assert(
  option(theme-booktabs(), "column-labels-border-bottom") != none,
  message: "booktabs rules under the column labels",
)
// Read off the preset rather than through `option`, which falls back to the
// default: `footer-border-top` defaults to `none`, so the door that yields a
// value cannot tell a preset that clears the rule from one that never mentions
// it. The preset must say so itself, since it does not build on the default.
#assert.eq(theme-booktabs().at("footer-border-top", default: "absent"), none)
#assert(option(theme-default(), "footer-border-top") != none, message: "the default rules the footer")

// theme-minimal rules the column labels and nothing else, where the default
// rules the table above and below as well.
#assert(
  option(theme-minimal(), "column-labels-border-bottom") != none,
  message: "minimal still rules under the column labels",
)
#assert.eq(theme-minimal().at("table-border-top", default: "absent"), none)
#assert.eq(theme-minimal().at("table-border-bottom", default: "absent"), none)
#assert(option(theme-default(), "table-border-top") != none, message: "the default rules the top")
#assert(option(theme-default(), "table-border-bottom") != none, message: "the default rules the bottom")

// --- merging follows call order ---

#let spec = build-spec(
  (units: (1,)),
  (table-options(row-striping: true), table-options(row-striping: false, cell-inset: 2em)),
  theme-default(),
)
#assert.eq(option(spec.options, "row-striping"), false)
#assert.eq(option(spec.options, "cell-inset"), 2em)

// A theme still shows through where no option replaced it.
#assert.eq(option(spec.options, "table-border-top"), option(theme-default(), "table-border-top"))
