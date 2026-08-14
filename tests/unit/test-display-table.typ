// The entry point renders content, and alignment is inferred per column.

#import "../../lib.typ": (
  columns-hide, columns-label, display-table, format-integer, format-number, table-header,
  table-source-note, theme-default,
)
#import "../../src/render/layout.typ": infer-alignment, slots-to-content

// --- alignment inference ---

#assert.eq(infer-alignment(((mass: 1.5), (mass: 2.5)), "mass"), end)
#assert.eq(infer-alignment(((name: "a"), (name: "b")), "name"), start)

// Missing values do not make a numeric column textual.
#assert.eq(infer-alignment(((mass: 1.5), (mass: none)), "mass"), end)

// A column with nothing in it falls back to start.
#assert.eq(infer-alignment(((mass: none),), "mass"), start)

// Numeric strings are text: keisen does not guess at coercion.
#assert.eq(infer-alignment(((mass: "1.5"),), "mass"), start)

// --- formatted slots to content ---

#assert.eq(
  slots-to-content((
    kind: "number",
    sign: "-",
    prefix: none,
    integer: "1 234",
    separator: ".",
    fraction: "50",
    exponent: none,
    suffix: none,
  )),
  // Written as an interpolated string: markup would read the leading hyphen as
  // a minus sign and split the literal into two pieces.
  [#"-1 234.50"],
)

// Content passes through; anything else becomes content, because a cell holds
// content and an unformatted column still carries its raw values.
#assert.eq(slots-to-content([raw]), [raw])
#assert.eq(slots-to-content("text"), [text])
#assert.eq(slots-to-content(42), [42])
#assert.eq(slots-to-content(none), [])

// --- the entry point ---

#let output = display-table(
  (mass: (1.5, 2.5), name: ("a", "b")),
  table-header(title: [Masses], subtitle: [In grams]),
  columns-label(mass: [Mass], name: [Name]),
  format-number("mass", decimals: 1),
  table-source-note([Source: scale.]),
)
#assert.eq(type(output), content)

// A table with no directives at all still renders.
#assert.eq(type(display-table((mass: (1,)))), content)

// A pre-built spec renders through the same path.
#import "../../src/spec.typ": build-spec
#let spec = build-spec((mass: (1,)), (columns-label(mass: [Mass]),), theme-default())
#assert.eq(type(display-table(spec: spec)), content)
