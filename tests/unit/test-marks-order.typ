// Marks follow the order a reader meets the cells, which grouping changes, and
// a spanner is addressed by the level it sits on.

#import "../../src/spec.typ": build-spec
#import "../../src/locations.typ": cells-body, cells-column-spanners
#import "../../src/parts/marks.typ": assign-marks, marks-for
#import "../../src/parts/notes.typ": table-footnote
#import "../../src/parts/spanners.typ": table-spanner
#import "../../src/parts/stub.typ": table-stub

// --- display order, not input order ---

// Rows 1 and 2 sit in different groups, so grouping puts input row 2 above
// input row 1. The marks must follow the page, not the data.
#let spec = build-spec(
  (name: ("a", "b", "c", "d"), region: ("N", "S", "N", "S"), units: (1, 2, 3, 4)),
  (
    table-stub(rowname: "name", group: "region"),
    table-footnote([On input row 1.], locations: cells-body(rows: 1)),
    table-footnote([On input row 2.], locations: cells-body(rows: 2)),
  ),
  (:),
)
#let footnotes = assign-marks(spec)

// Input row 2 renders in the first group, so it is met first and marked first.
#assert.eq(marks-for(footnotes, "body", 2, "units"), ("1",))
#assert.eq(marks-for(footnotes, "body", 1, "units"), ("2",))

// --- left to right within a row ---

#let across = assign-marks(build-spec(
  (first: (1,), second: (2,)),
  (
    table-footnote([Right.], locations: cells-body(columns: "second")),
    table-footnote([Left.], locations: cells-body(columns: "first")),
  ),
  (:),
))
#assert.eq(marks-for(across, "body", 0, "first"), ("1",))
#assert.eq(marks-for(across, "body", 0, "second"), ("2",))

// --- a spanner above level one still takes its mark ---

#let stacked = build-spec(
  (a: (1,), b: (2,)),
  (
    table-spanner([Inner], ("a", "b")),
    table-spanner([Outer], ("a", "b"), level: 2),
    table-footnote([On the outer spanner.], locations: cells-column-spanners(spanners: [Outer])),
  ),
  (:),
)
#assert.eq(marks-for(assign-marks(stacked), "column-spanners", 2, [Outer]), ("1",))
