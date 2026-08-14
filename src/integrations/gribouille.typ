///! Nanoplot renderers built on gribouille.
///!
///! The only file in the package that imports a third-party package. Typst
///! resolves imports per file at compile time, so a document that never imports
///! this module never fetches gribouille.
///!
///! Size floor: gribouille refuses a canvas below 0.5 cm in either direction,
///! so these renderers need roughly 3em of height at a 10pt text size rather
///! than the 0.8em a Tufte sparkline would take. Nanoplot rows are therefore
///! taller than text rows. A renderer drawn with native Typst primitives could
///! go smaller, and `format-nanoplot` takes any function, so nothing here
///! prevents one.

#import "@preview/gribouille:0.6.0": aes, geom-col, geom-line, geom-point, plot, scale-continuous, scales, theme-void

#import "../utils/errors.typ": check

// gribouille refuses a canvas below this in either direction, so the failure is
// reported in keisen's own grammar rather than as a third-party panic.
#let _floor = 0.55cm

#let _check-size(width, height) = context {
  for (name, size) in (("width", width), ("height", height)) {
    check(
      size.to-absolute() >= _floor,
      "nanoplot",
      name + " is below the minimum gribouille draws",
      value: size,
      hint: "These renderers need about 0.55cm, roughly 3em at 10pt; a smaller one must be drawn natively.",
    )
  }
}

#let _frame(numbers) = numbers.enumerate().map(((index, value)) => (x: index, y: value))

// gribouille sizes its canvas in absolute units, so the em-relative box the
// nanoplot protocol works in is resolved against the surrounding text first.
#let _panel(layers, numbers, domain, width, height) = context {
  _check-size(width, height)
  plot(
  data: _frame(numbers),
  mapping: aes(x: "x", y: "y"),
  layers: layers,
  // The shared domain is the point of a nanoplot: without it every cell
  // autoscales and a flat series looks like a volatile one.
  scales: if domain == none { (:) } else {
    scales(y: scale-continuous(limits: domain))
  },
  theme: theme-void(),
    width: width.to-absolute(),
    height: height.to-absolute(),
  )
}

// A sparkline: the shape of a series, without axes or labels, sized to sit on
// the text baseline.
#let nanoplot-line(numbers, domain: none, width: 4em, height: 0.8em) = {
  _panel((geom-line(),), numbers, domain, width, height)
}

// The same series as bars, for counts rather than a trend.
#let nanoplot-bar(numbers, domain: none, width: 4em, height: 0.8em) = {
  _panel((geom-col(),), numbers, domain, width, height)
}

// A trend with its readings marked, for series short enough to show both.
#let nanoplot-points(numbers, domain: none, width: 4em, height: 0.8em) = {
  _panel((geom-line(), geom-point(size: 1pt)), numbers, domain, width, height)
}
