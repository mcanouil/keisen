// `columns-align` says where a column sits, and until now every test of it was
// a refusal: six expect-fail fixtures carry the scope and nothing read the
// alignment it produces. Making the directive ignore its argument left the whole
// suite green.
//
// The alignment reaches the renderer twice over: `spec.align` carries what the
// directives resolved to, and `column-alignments` is the call the renderer makes
// for the row of columns, so the inferred default shows there and nowhere else.

#import "../../src/parts/columns.typ": columns-align
#import "../../src/render/layout.typ": column-alignments
#import "../../src/spec.typ": build-spec

#let data = (product: ("Bolt", "Nut"), units: (10, 20), note: ("light", "heavy"))

// --- nothing named, so every column is inferred ---
//
// Numbers sit against the end edge and everything else against the start edge,
// which is the default this directive overrides.
#assert.eq(column-alignments(build-spec(data, (), (:))), (start, end, start))

// --- a named column, and only it ---

#let named = build-spec(data, (columns-align(center, columns: "units"),), (:))
#assert.eq(named.align, (units: center))
#assert.eq(column-alignments(named), (start, center, start))

// --- columns: auto covers every column ---
//
// The default of the parameter, so `columns-align(end)` is the whole table.

#let every = build-spec(data, (columns-align(end),), (:))
#assert.eq(every.align, (product: end, units: end, note: end))
#assert.eq(column-alignments(every), (end, end, end))

// --- the last directive wins, as everywhere else ---

#let twice = build-spec(
  data,
  (columns-align(center, columns: "units"), columns-align(start, columns: "units")),
  (:),
)
#assert.eq(column-alignments(twice), (start, start, start))
