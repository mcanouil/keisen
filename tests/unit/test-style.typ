// Styles are resolved once into an index keyed by cell address, and a later
// directive replaces an earlier one property by property.

#import "../../src/locations.typ": cells-body, cells-column-labels
#import "../../src/spec.typ": build-spec
#import "../../src/style.typ": build-index, style, style-for, table-style

// --- the builder keeps only what was set ---

#assert.eq(style(fill: red), (fill: red))
#assert.eq(style(text: (weight: "bold")).text, (weight: "bold"))
#assert.eq(style(), (:))

// --- the directive is a plain dictionary, like every other ---

#let directive = table-style(style(fill: red), locations: cells-body(columns: "units"))
#assert.eq(directive.kind, "style")

// --- resolution ---

#let spec = build-spec(
  (units: (10, 20), price: (1.5, 2.5)),
  (
    table-style(style(fill: red), locations: cells-body(columns: "units")),
    table-style(
      style(fill: blue, align: center),
      locations: cells-body(columns: "units", rows: row => row.units > 15),
    ),
    table-style(style(text: (weight: "bold")), locations: cells-column-labels()),
  ),
  (:),
)

#let index = build-index(spec)

// The column-wide style reaches the row the second directive does not.
#assert.eq(style-for(index, "body", 0, "units"), (fill: red))

// Where both match, the later one wins property by property, and properties the
// later one does not set survive.
#assert.eq(style-for(index, "body", 1, "units"), (fill: blue, align: center))

// A cell no location named has no style at all.
#assert.eq(style-for(index, "body", 0, "price"), (:))

// Parts other than the body resolve the same way.
#assert.eq(style-for(index, "column-labels", none, "units"), (text: (weight: "bold")))
#assert.eq(style-for(index, "column-labels", none, "price"), (text: (weight: "bold")))

// An empty spec resolves to an empty index rather than failing.
#assert.eq(build-index(build-spec((units: (1,)), (), (:))), (:))
