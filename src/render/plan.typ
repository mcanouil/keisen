///! Row plan describing every rendered row.
///!
///! Layout builds this once and reads it for everything afterwards: which part
///! a row belongs to, which native header level carries it, which input row it
///! came from, and whether it takes a stripe. Nothing downstream does row
///! arithmetic of its own.

#let entry(part, level: none, source: none, stripe: false) = (
  part: part,
  level: level,
  source: source,
  stripe: stripe,
)

#let build-plan(spec) = {
  let plan = ()

  // Level 1: the title block, which does not repeat across page breaks.
  if spec.header.title != none { plan.push(entry("title", level: 1)) }
  if spec.header.subtitle != none { plan.push(entry("subtitle", level: 1)) }

  // Level 2: the column labels, which do.
  plan.push(entry("labels", level: 2))

  // Striping is computed from the body row position here rather than from a
  // show rule at render time, so its phase survives a page break.
  for (position, row) in spec.data.enumerate() {
    plan.push(entry("body", source: position, stripe: calc.odd(position)))
  }

  for (position, note) in spec.source-notes.enumerate() {
    plan.push(entry("source-note", source: position))
  }

  plan
}
