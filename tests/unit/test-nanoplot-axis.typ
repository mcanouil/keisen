// A renderer may draw an axis above the first body row and below the last. The
// axis rows are plan parts of their own: no location names them, and they take
// no stripe, so the body rows around them keep their phase.

#import "../../lib.typ": display-table, format-nanoplot, nanoplot-line
#import "../../src/format/apply.typ": column-axes
#import "../../src/locations.typ": PARTS
#import "../../src/parts/stub.typ": table-row-group
#import "../../src/parts/summaries.typ": aggregate-sum, grand-summary-rows, summary-rows
#import "../../src/render/plan.typ": build-plan
#import "../../src/spec.typ": build-spec

#let trends = (
  (1.0, 1.2, 1.1, 1.4, 1.8, 2.1),
  (2.0, 1.8, 1.6, 1.5, 1.2, 0.9),
  (1.5, 1.5, 1.6, 1.5, 1.7, 1.6),
  (1.0, 1.1, 1.3, 1.2, 1.4, 1.5),
)

#let with-axis = nanoplot-line() + (axis: (domain: none, width: none, side: none) => if side == "top" [top] else [bottom])
#let recording = nanoplot-line() + (
  axis: (domain: none, width: none, side: none) => repr((domain: domain, width: width, side: side)),
)

#let parts(spec) = build-plan(spec).rows.map(entry => entry.part)
#let data = (units: (1, 2, 3, 4), trend: trends)
#let spec-for(plot, ..directives, data: data) = build-spec(
  data,
  (format-nanoplot("trend", plot: plot),) + directives.pos(),
  (:),
)

#let axis-spec = spec-for(with-axis)
#let plain-spec = spec-for(nanoplot-line())

// After the labels, and right after the last body row.
#assert.eq(parts(axis-spec), ("labels", "axis-top", "body", "body", "body", "body", "axis-bottom"))
// A renderer without an axis adds no rows.
#assert("axis-top" not in parts(plain-spec))
#assert("axis-bottom" not in parts(plain-spec))

// No readings, no domain, no rows.
#let empty-spec = spec-for(with-axis, data: (units: (1, 2), trend: ((), ())))
#assert("axis-top" not in parts(empty-spec))
#assert("axis-bottom" not in parts(empty-spec))

// One row, and the column without an axis has none there.
#let mixed-spec = build-spec(
  (first: trends, second: trends),
  (format-nanoplot("first", plot: with-axis), format-nanoplot("second", plot: nanoplot-line())),
  (:),
)
#assert.eq(column-axes(mixed-spec).map(axes => axes.top), ([top], none))
#assert.eq(column-axes(mixed-spec).map(axes => axes.bottom), ([bottom], none))
#assert.eq(parts(mixed-spec).filter(part => part.starts-with("axis")), ("axis-top", "axis-bottom"))

// A column that holds no nanoplot has no axis.
#assert.eq(column-axes(axis-spec).map(axes => axes.top), (none, [top]))

// After the last body row, before the last group's summaries, and the axis
// takes no stripe and does not shift the phase.
#let grouped-spec = build-spec(
  data,
  (
    format-nanoplot("trend", plot: with-axis),
    table-row-group([A], (0, 1)),
    table-row-group([B], (2, 3)),
    summary-rows(functions: (Subtotal: aggregate-sum), columns: ("units",)),
    grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units",)),
  ),
  (:),
)
#assert.eq(parts(grouped-spec).slice(-3), ("axis-bottom", "summary", "grand-summary"))
#assert.eq(
  build-plan(grouped-spec).rows.filter(entry => entry.part == "body").map(entry => entry.stripe),
  (false, true, false, true),
)
#assert(build-plan(grouped-spec).rows.filter(entry => entry.part.starts-with("axis")).all(entry => not entry.stripe))

// The axis is drawn at the content width with the column's domain.
#assert.eq(
  column-axes(spec-for(recording)).at(1).top,
  repr((domain: (0.9, 2.1), width: 4em, side: "top")),
)
#assert.eq(
  column-axes(spec-for(recording)).at(1).bottom,
  repr((domain: (0.9, 2.1), width: 4em, side: "bottom")),
)

// No location reaches the axis rows.
#assert("axis-top" not in PARTS.values())
#assert("axis-bottom" not in PARTS.values())

// The table assembles with the axis rows in it.
#context {
  let _ = measure(display-table(data, format-nanoplot("trend", plot: with-axis)))
}
