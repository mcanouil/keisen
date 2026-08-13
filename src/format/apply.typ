///! Selector matching and format application.
///!
///! Selectors are uniform across every directive, and every predicate takes one
///! argument: Typst closures fail on arity mismatch, and `row => ..` is what
///! people write. Row position travels on the reserved `_index` key instead of
///! a second parameter.

#import "../parts/substitutions.typ": is-missing, is-zero
#import "../utils/errors.typ": fail-type

#let matches-column(selector, name) = {
  if selector == auto {
    true
  } else if type(selector) == str {
    selector == name
  } else if type(selector) == array {
    name in selector
  } else if type(selector) == function {
    selector(name)
  } else {
    fail-type("columns", "selector", selector, "auto, a name, an array of names, or a predicate")
  }
}

#let matches-row(selector, row) = {
  if selector == auto {
    true
  } else if type(selector) == int {
    row._index == selector
  } else if type(selector) == array {
    row._index in selector
  } else if type(selector) == function {
    selector(row)
  } else {
    fail-type("rows", "selector", selector, "auto, an index, an array of indices, or a predicate")
  }
}

// The last matching directive wins for a given cell, which makes "format the
// column, then override a few rows" read in the order it is written. Formatters
// always see the raw value, never an already-formatted one, so replacing rather
// than composing is safe.
// Substitutions are tested before formatting, so a gap never reaches a
// formatter that would refuse it, and a substituted cell is opaque content.
#let _substitution(substitutions, name, row, value) = {
  let chosen = none
  for directive in substitutions {
    if not matches-column(directive.columns, name) { continue }
    if not matches-row(directive.rows, row) { continue }
    let applies = if directive.test == "missing" { is-missing(value) } else { is-zero(value) }
    if applies { chosen = directive }
  }
  chosen
}

#let apply-formats(rows, formats, name, substitutions: ()) = {
  rows.map(row => {
    let value = row.at(name, default: none)

    let substitution = _substitution(substitutions, name, row, value)
    if substitution != none { return substitution.replacement }

    let chosen = none
    for directive in formats {
      if matches-column(directive.columns, name) and matches-row(directive.rows, row) {
        chosen = directive
      }
    }
    if chosen == none { value } else { (chosen.function)(value) }
  })
}
