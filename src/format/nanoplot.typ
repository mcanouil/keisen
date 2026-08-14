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
  for (name, size) in (("width", width), ("height", height)) {
    check(
      type(size) != fraction,
      "format-nanoplot",
      name + " cannot be a fraction",
      value: size,
      hint: "Give it in em or pt: resolving a fraction inside a cell forbids page breaking there.",
    )
  }

  // The domain is what makes a column of nanoplots comparable, so the column's
  // values are required rather than quietly falling back to per-cell scaling.
  check(
    values != none or domain != auto,
    "format-nanoplot",
    "no values to scale against",
    hint: "Pass values: the whole column, or domain: an explicit (low, high).",
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
