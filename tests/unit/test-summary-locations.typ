// Summary rows are the likeliest thing anyone wants to pick out of a financial
// table, and nothing could address them: the renderer looked up styles for the
// summary parts and no location produced their addresses, so every lookup
// missed and the style silently did nothing.

#import "../../lib.typ": (
  aggregate-sum, cells-body, cells-grand-summary, cells-summary, format-number, grand-summary-rows,
  style, summary-rows, table-footnote, table-stub, table-style,
)
#import "../../src/locations.typ": expand
#import "../../src/parts/marks.typ": assign-marks, marks-for
#import "../../src/spec.typ": build-spec
#import "../../src/style.typ": build-index, style-for

#let data = (
  region: ("North", "North", "South", "South"),
  product: ("Bolt", "Nut", "Beam", "Plate"),
  units: (1250, 860, 430, 2100),
  revenue: (18750.5, 12900.25, 21500, 31500.75),
)

#let spec = build-spec(
  data,
  (
    table-stub(rowname: "product", group: "region"),
    format-number("revenue", decimals: 2),
    summary-rows(functions: (Subtotal: aggregate-sum, Mean: aggregate-sum), columns: ("units", "revenue")),
    grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units", "revenue")),
  ),
  (:),
)

// The address carries the same row key the row plan uses, `(group:, row:)`, so
// the style index and the renderer agree on which cell is meant. A key that
// merely looks plausible expands, matches nothing, and reports nothing.
#let every-summary = expand(cells-summary(), spec)
#assert.eq(every-summary.first().part, "summary")
#assert.eq(every-summary.first().row, (group: 0, row: 0))

// Two groups, two summary rows each, two visible columns, plus the label cell
// in the stub: 2 * 2 * 3.
#assert.eq(every-summary.len(), 12)

// The label cell is addressed as the stub cell of the summary row, so styling
// the summary picks up the row rather than everything except its name.
#assert.eq(every-summary.filter(address => address.column == none).len(), 4)

// The label cell alone, which is how a note goes on the row once instead of on
// every cell in it.
#let labels-only = expand(cells-summary(columns: none), spec)
#assert.eq(labels-only.len(), 4)
#assert.eq(labels-only.map(address => address.column).dedup(), (none,))

// Without a stub the label sits in the first visible column, so that is the
// cell `columns: none` means there.
#let unstubbed = build-spec(
  data,
  (grand-summary-rows(functions: (Total: aggregate-sum), columns: "units"),),
  (:),
)
#assert.eq(
  expand(cells-grand-summary(columns: none), unstubbed),
  ((part: "grand-summary", row: 0, column: "region"),),
)

#let one-column = expand(cells-summary(columns: "units"), spec)
#assert.eq(one-column.len(), 4)
#assert.eq(one-column.map(address => address.column).dedup(), ("units",))

// Groups are selected by label, as everywhere else.
#let south = expand(cells-summary(groups: "South"), spec)
#assert.eq(south.map(address => address.row.group).dedup(), (1,))

// A summary row is selected by the label that names it, or by its position
// within the group, since both are how a reader would say which one.
#let subtotals = expand(cells-summary(rows: "Subtotal"), spec)
#assert.eq(subtotals.len(), 6)
#assert.eq(subtotals.map(address => address.row.row).dedup(), (0,))

#let seconds = expand(cells-summary(rows: 1), spec)
#assert.eq(seconds.map(address => address.row.row).dedup(), (1,))
#assert.eq(expand(cells-summary(rows: label => label == "Mean"), spec), seconds)

// The grand summary sits outside the groups, so its row key is a position.
#let grand = expand(cells-grand-summary(), spec)
#assert.eq(grand.first().part, "grand-summary")
#assert.eq(grand.map(address => address.row).dedup(), (0,))
#assert.eq(grand.len(), 3)
#assert.eq(expand(cells-grand-summary(columns: "revenue"), spec).len(), 1)
#assert.eq(expand(cells-grand-summary(rows: "Total"), spec).len(), 3)
// A label no summary carries is a typo and is reported; see
// tests/expect-fail/location-unknown-summary-row.typ. A predicate is a filter,
// so matching nothing stays silent.
#assert.eq(expand(cells-grand-summary(rows: label => false), spec), ())

// The addresses are worth nothing unless the index the renderer reads holds
// them. These are the exact keys `assemble` looks up, so a location that
// expanded to a plausible but different key would fail here rather than
// silently styling nothing, which is what it did before.
#let highlighted = build-spec(
  data,
  (
    table-stub(rowname: "product", group: "region"),
    summary-rows(functions: (Subtotal: aggregate-sum), columns: ("units", "revenue")),
    grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units", "revenue")),
    table-style(style(fill: red), locations: cells-summary(columns: "units")),
    table-style(style(text: (weight: "bold")), locations: cells-grand-summary()),
  ),
  (:),
)
#let index = build-index(highlighted)
#assert.eq(style-for(index, "summary", (group: 0, row: 0), "units"), (fill: red))
#assert.eq(style-for(index, "summary", (group: 1, row: 0), "units"), (fill: red))
#assert.eq(style-for(index, "summary", (group: 0, row: 0), "revenue"), (:))
#assert.eq(style-for(index, "grand-summary", 0, "units"), (text: (weight: "bold")))

// The stub cell of the grand summary is where its label sits, and it takes the
// style too, so highlighting a total does not leave its name unhighlighted.
#assert.eq(style-for(index, "grand-summary", 0, none), (text: (weight: "bold")))

// A footnote reaches a summary cell as well, and its mark is numbered after the
// body rows it follows rather than before them.
#let noted = build-spec(
  data,
  (
    table-stub(rowname: "product", group: "region"),
    summary-rows(functions: (Subtotal: aggregate-sum), columns: "units"),
    table-footnote([Excludes returns.], locations: cells-summary(groups: "North", columns: "units")),
    table-footnote([Measured at the till.], locations: cells-body(columns: "units", rows: 0)),
  ),
  (:),
)
#let footnotes = assign-marks(noted)
#assert.eq(marks-for(footnotes, "summary", (group: 0, row: 0), "units").len(), 1)
#assert.eq(marks-for(footnotes, "summary", (group: 1, row: 0), "units"), ())
#assert.eq(marks-for(footnotes, "body", 0, "units"), ("1",))
#assert.eq(marks-for(footnotes, "summary", (group: 0, row: 0), "units"), ("2",))

// Without a stub the label occupies the first visible column, which is already
// addressed by name, so no separate label cell exists to address.
#let plain = build-spec(
  data,
  (grand-summary-rows(functions: (Total: aggregate-sum), columns: "units"),),
  (:),
)
#assert.eq(expand(cells-grand-summary(), plain).filter(address => address.column == none), ())
