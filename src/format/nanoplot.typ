///! Nanoplot protocol and shared domains.
///!
///! The core owns the protocol, the domain, and the cell box, and ships no
///! renderer: a nanoplot is drawn by whichever function is passed as `plot`,
///! and src/integrations/gribouille.typ provides the ones this package
///! recommends.
///!
///! The domain spans every row in the column, because comparability down the
///! column is the whole point of a nanoplot: sparklines scaled per cell say
///! nothing.

#import "../utils/errors.typ": check, fail-type
#import "number.typ": format

#let _values-of(value) = {
  if type(value) != array { return () }
  value
    .filter(entry => type(entry) in (int, float, decimal))
    .map(entry => if type(entry) == decimal { float(entry) } else { entry })
}

// The domain across every row of the column, so each cell draws on the same
// scale. An explicit domain overrides it.
#let shared-domain(values, given: auto) = {
  if given != auto { return given }
  let numbers = values.map(_values-of).flatten()
  if numbers.len() == 0 { return none }
  (calc.min(..numbers), calc.max(..numbers))
}

#let format-nanoplot(
  columns,
  rows: auto,
  plot: none,
  width: 4em,
  height: 0.8em,
  baseline: 15%,
  domain: auto,
  values: none,
) = {
  if type(plot) != function {
    fail-type("format-nanoplot", "plot", plot, "a renderer function")
  }
  // A fractional width would have to be resolved inside the cell with layout(),
  // which forbids page breaking there; em and pt need no such thing.
  check(
    type(width) != fraction,
    "format-nanoplot",
    "width cannot be a fraction",
    value: width,
    hint: "Give the width in em or pt so the cell stays breakable.",
  )

  format(
    columns,
    rows: rows,
    value => {
      let numbers = _values-of(value)
      if numbers.len() == 0 { return [] }
      let scale = shared-domain(if values == none { (value,) } else { values }, given: domain)
      box(
        width: width,
        height: height,
        baseline: baseline,
        plot(numbers, domain: scale, width: width, height: height),
      )
    },
  )
}
