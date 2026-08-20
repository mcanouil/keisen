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
#assert.eq(option(theme-compact(), "table-font-size"), 0.9em)
#assert.eq(option(theme-compact(), "table-border-top"), option(theme-default(), "table-border-top"))

// theme-booktabs is the three-line rule: a heavy rule above and below, a light
// one under the column labels, and nothing under the footer.
#assert.eq(option(theme-booktabs(), "table-border-top"), 1pt + black)
#assert.eq(option(theme-booktabs(), "table-border-bottom"), 1pt + black)
#assert.eq(option(theme-booktabs(), "column-labels-border-bottom"), 0.5pt + black)
#assert.eq(option(theme-booktabs(), "footer-border-top"), none)

// theme-minimal rules the column labels lightly and draws no table border,
// where the default draws one above and one below.
#assert.eq(option(theme-minimal(), "column-labels-border-bottom"), 0.5pt + luma(200))
#assert.eq(option(theme-minimal(), "table-border-top"), none)
#assert.eq(option(theme-minimal(), "table-border-bottom"), none)
#assert(option(theme-default(), "table-border-top") != none)
#assert(option(theme-default(), "table-border-bottom") != none)

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
