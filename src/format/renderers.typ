///! Nanoplot renderers drawn with native Typst primitives.
///!
///! A nanoplot is a shape, not a chart: no axes, no labels, no legend. Native
///! `curve`, `rect`, and `circle` inside a `box` draw one in a few lines, so the
///! package needs no plotting dependency and no third-party canvas.
///!
///! Every coordinate is computed as a fraction of the box and multiplied by the
///! width or height only when it is drawn, so the caller's units are whatever
///! they gave: an `em` size tracks `set text(size: ..)`, needs no absolute
///! resolution, and never has to be compared against a length in other units.
///! That is what lets a sparkline sit at 0.8em, the height Tufte's guidance and
///! Typst's em semantics both point at.
///!
///! A renderer is a dictionary `(kind: "nanoplot-renderer", draw, readings,
///! axis)`. `format-nanoplot` accepts any dictionary of this shape, so a
///! renderer written in a document works exactly as well as these three.

#import "../utils/errors.typ": check, fail-type
#import "nanoplot.typ": values-of

// The ink follows the surrounding text unless a colour is given, so a plot in a
// styled cell is drawn in that cell's colour rather than in a fixed black.
#let _ink(given) = if given == auto { text.fill } else { given }

// Falls back to the series' own range, so a renderer called by hand outside
// `format-nanoplot` still draws. Inside it, the domain always spans the column.
#let _range(numbers, domain) = {
  if domain != none { return (float(domain.first()), float(domain.last())) }
  (calc.min(..numbers), calc.max(..numbers))
}

// Fractions of the box: index across it, value up it. A domain of zero span
// would divide by nothing, so a flat series draws along the middle rather than
// at an edge, and a single reading sits in the centre rather than at the left.
#let _fractions(numbers, low, high) = {
  let span = high - low
  let last = numbers.len() - 1
  numbers
    .enumerate()
    .map(((index, value)) => (
      if last == 0 { 0.5 } else { index / last },
      if span == 0 { 0.5 } else { 1 - (value - low) / span },
    ))
}

#let _dot(fraction, width, height, radius, paint) = {
  let (fx, fy) = fraction
  place(top + left, dx: width * fx - radius, dy: height * fy - radius, circle(radius: radius, fill: paint))
}

// The frame every renderer draws in: the numbers, the empty-series answer, the
// domain, and the box the contents are clipped to. `draw(values, low, high)`
// supplies the contents, and runs inside the context this opens, so `_ink`
// resolves `text.fill` there as it would written out here.
#let _canvas(numbers, domain, width, height, draw) = {
  if numbers.len() == 0 { return box(width: width, height: height) }
  context {
    let (low, high) = _range(numbers, domain)
    box(
      width: width,
      height: height,
      // A value outside the domain would otherwise be drawn outside the cell,
      // across whatever sits beside it. An explicit domain is a choice to look
      // at one window of the data, so what falls outside it is not drawn.
      clip: true,
      draw(numbers, low, high),
    )
  }
}

// A sparkline: the shape of a series, without axes or labels.
#let _line(numbers, domain: none, width: 4em, height: 0.8em, stroke: auto, thickness: 0.6pt) = {
  _canvas(numbers, domain, width, height, (values, low, high) => {
    let fractions = _fractions(values, low, high)
    let paint = _ink(stroke)
    // A single reading has no line to draw, so it draws as the point it is.
    if fractions.len() == 1 {
      _dot(fractions.first(), width, height, thickness, paint)
    } else {
      curve(
        stroke: thickness + paint,
        ..fractions
          .enumerate()
          .map(((index, fraction)) => {
            let point = (width * fraction.first(), height * fraction.last())
            if index == 0 { curve.move(point) } else { curve.line(point) }
          }),
      )
    }
  })
}

// A trend with its readings marked, for series short enough to show both.
#let _points(
  numbers,
  domain: none,
  width: 4em,
  height: 0.8em,
  stroke: auto,
  thickness: 0.6pt,
  radius: 1pt,
) = {
  _canvas(numbers, domain, width, height, (values, low, high) => {
    let paint = _ink(stroke)
    // The line is drawn by the renderer above, in a box of the same size, so
    // the marks laid over it land on the same coordinates.
    place(top + left, _line(
      values,
      domain: (low, high),
      width: width,
      height: height,
      stroke: paint,
      thickness: thickness,
    ))
    _fractions(values, low, high).map(fraction => _dot(fraction, width, height, radius, paint)).join()
  })
}

// The same series as bars, for counts rather than a trend.
//
// Bars are measured from zero, not from the domain's low: a bar drawn from 5 to
// 10 makes a small difference look like the whole quantity, which is the lie the
// shared domain exists to prevent. The line renderers scale to the domain
// instead, because a trend is about shape rather than magnitude.
#let _bar(numbers, domain: none, width: 4em, height: 0.8em, fill: auto, gap: 30%) = {
  _canvas(numbers, domain, width, height, (values, low, high) => {
    let base = calc.min(0.0, low)
    let peak = calc.max(0.0, high)
    let span = peak - base
    let pitch = 1 / values.len()
    let thick = pitch * (1 - gap / 100%)
    let paint = _ink(fill)
    // Every reading is zero, so every bar is, and there is no span to measure
    // against either.
    if span == 0 { [] } else {
      let zero = 1 - (0 - base) / span
      values
        .enumerate()
        .map(((index, value)) => {
          let level = 1 - (value - base) / span
          place(
            top + left,
            dx: width * (pitch * index + (pitch - thick) / 2),
            dy: height * calc.min(level, zero),
            rect(
              width: width * thick,
              height: height * calc.abs(level - zero),
              fill: paint,
              stroke: none,
            ),
          )
        })
        .join()
    }
  })
}

// Read when the renderer is built, and whether or not there is anything to
// draw: whether a gap leaves the bars some width does not depend on the data.
#let _check-gap(gap) = {
  // The type is tested first, because the range test compares against a
  // percentage and anything else fails that comparison rather than this check.
  if type(gap) != ratio {
    fail-type(
      "nanoplot-bar",
      "gap",
      gap,
      "a percentage of the bar pitch",
      hint: "Give a percentage of the bar pitch below 100%.",
    )
  }
  // Two ends of one range, said apart: a gap at or above the pitch leaves no bar
  // to draw, and a gap below zero would draw each bar over its neighbours. One
  // message covering both described neither.
  check(
    gap >= 0%,
    "nanoplot-bar",
    "gap cannot be negative",
    value: gap,
    hint: "A gap is the share of the bar pitch left empty between the bars.",
  )
  check(
    gap < 100%,
    "nanoplot-bar",
    "gap must leave the bars some width",
    value: gap,
    hint: "Give a percentage of the bar pitch below 100%.",
  )
}

// The three draw a series of numbers, so each reads the cell value with the
// same function it gives as its readings.
#let _renderer(plot) = (
  kind: "nanoplot-renderer",
  draw: (value, domain: none, width: 4em, height: 0.8em) => plot(
    values-of(value),
    domain: domain,
    width: width,
    height: height,
  ),
  readings: values-of,
  axis: none,
)

#let nanoplot-line(stroke: auto, thickness: 0.6pt) = _renderer(_line.with(stroke: stroke, thickness: thickness))

#let nanoplot-points(stroke: auto, thickness: 0.6pt, radius: 1pt) = _renderer(
  _points.with(stroke: stroke, thickness: thickness, radius: radius),
)

#let nanoplot-bar(fill: auto, gap: 30%) = {
  _check-gap(gap)
  _renderer(_bar.with(fill: fill, gap: gap))
}
