// The row plan describes every rendered row, and every later layout decision
// is a lookup into it.

#import "../../src/spec.typ": build-spec
#import "../../src/render/plan.typ": build-plan
#import "../../src/parts/header.typ": table-header
#import "../../src/parts/notes.typ": table-source-note

#let spec = build-spec(
  (mass: (1, 2)),
  (table-header(title: [Masses]), table-source-note([Source: scale.])),
  (:),
)
#let plan = build-plan(spec)

#assert.eq(
  plan.map(entry => entry.part),
  ("title", "labels", "body", "body", "source-note"),
)

// Header levels: the title never repeats, the column labels always do.
#assert.eq(plan.first().level, 1)
#assert.eq(plan.at(1).level, 2)

// Body entries point back at their input row.
#assert.eq(plan.at(2).source, 0)
#assert.eq(plan.at(3).source, 1)

// Striping counts body rows alone, so it survives whatever sits above them.
#assert.eq(plan.at(2).stripe, false)
#assert.eq(plan.at(3).stripe, true)

// Non-body rows are never striped.
#assert.eq(plan.first().stripe, false)
#assert.eq(plan.last().stripe, false)

// A subtitle adds its own row; no header adds none.
#let with-subtitle = build-plan(build-spec(
  (mass: (1,)),
  (table-header(title: [Masses], subtitle: [In grams]),),
  (:),
))
#assert.eq(with-subtitle.map(entry => entry.part), ("title", "subtitle", "labels", "body"))

#let bare = build-plan(build-spec((mass: (1,)), (), (:)))
#assert.eq(bare.map(entry => entry.part), ("labels", "body"))

// An empty table still plans its labels.
#assert.eq(build-plan(build-spec((:), (), (:))).map(entry => entry.part), ("labels",))
