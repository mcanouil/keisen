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
  // show rule at render time, so its phase survives a page break. It counts
  // body rows alone, so a group label never takes a stripe or shifts the phase.
  // Ungrouped data is one nameless block, so both shapes take the same loop.
  let blocks = if spec.groups.len() == 0 {
    ((none, range(spec.data.len())),)
  } else {
    spec.groups.enumerate().map(((index, group)) => (index, group.rows))
  }

  let stripe = 0
  for (index, positions) in blocks {
    // Level 3: the group label, which repeats until the next group retires it,
    // so a group spanning a page break reprints its name.
    if index != none { plan.push(entry("group", level: 3, source: index)) }
    for position in positions {
      plan.push(entry("body", source: position, stripe: calc.odd(stripe)))
      stripe += 1
    }
  }

  for (position, note) in spec.source-notes.enumerate() {
    plan.push(entry("source-note", source: position))
  }

  plan
}
