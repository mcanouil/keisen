///! Group and grand summary rows.
///!
///! An aggregation is any `values => value`, so the built-ins below and a
///! bespoke closure are interchangeable. They run on raw values, before the
///! format stage, which is what lets a summary cell format through the same
///! path as the body cells above it.

#import "../data.typ": column
#import "../format/apply.typ": matches-column
#import "../utils/errors.typ": check

// Gaps are skipped rather than poisoning the result: a column with one missing
// reading still has a mean.
#let _numbers(values) = {
  values
    .filter(value => type(value) in (int, float, decimal))
    .map(value => if type(value) == decimal { float(value) } else { value })
}

#let aggregate-sum(values) = {
  let numbers = _numbers(values)
  if numbers.len() == 0 { return none }
  numbers.sum()
}

#let aggregate-count(values) = _numbers(values).len()

#let aggregate-mean(values) = {
  let numbers = _numbers(values)
  if numbers.len() == 0 { return none }
  numbers.sum() / numbers.len()
}

#let aggregate-min(values) = {
  let numbers = _numbers(values)
  if numbers.len() == 0 { return none }
  calc.min(..numbers)
}

#let aggregate-max(values) = {
  let numbers = _numbers(values)
  if numbers.len() == 0 { return none }
  calc.max(..numbers)
}

// Linear interpolation between order statistics, which is R's type 7 default;
// stated here because the nine competing definitions disagree.
#let aggregate-quantile(probability) = values => {
  check(
    probability >= 0 and probability <= 1,
    "aggregate-quantile",
    "probability must lie between 0 and 1",
    value: probability,
  )
  let numbers = _numbers(values).sorted()
  if numbers.len() == 0 { return none }
  if numbers.len() == 1 { return numbers.first() }
  let position = probability * (numbers.len() - 1)
  let lower = int(calc.floor(position))
  let upper = int(calc.ceil(position))
  if lower == upper { return numbers.at(lower) }
  numbers.at(lower) + (position - lower) * (numbers.at(upper) - numbers.at(lower))
}

#let aggregate-median = aggregate-quantile(0.5)

// The sample definition, with n - 1 in the denominator.
#let aggregate-standard-deviation(values) = {
  let numbers = _numbers(values)
  if numbers.len() < 2 { return none }
  let mean = numbers.sum() / numbers.len()
  calc.sqrt(numbers.map(value => calc.pow(value - mean, 2)).sum() / (numbers.len() - 1))
}

// `functions` is named rather than positional so the call reads as what it is,
// a dictionary of label to aggregation: summary-rows(functions: (Total: sum)).
#let summary-rows(functions: (:), columns: auto, groups: auto, format: none) = (
  kind: "summary",
  scope: "group",
  functions: functions,
  columns: columns,
  groups: groups,
  format: format,
)

#let grand-summary-rows(functions: (:), columns: auto, format: none) = (
  kind: "summary",
  scope: "grand",
  functions: functions,
  columns: columns,
  groups: auto,
  format: format,
)

// How many rows a set of summary directives produces: one per named function.
#let summary-count(directives) = directives.map(directive => directive.functions.len()).sum(default: 0)

// One entry per summary row: its label and the aggregated value per column.
#let _rows-for(directives, rows, columns) = {
  directives
    .map(directive => directive.functions
      .pairs()
      .map(((label, aggregate)) => (
        label: label,
        format: directive.format,
        values: {
          let out = (:)
          for name in columns.filter(name => matches-column(directive.columns, name)) {
            out.insert(name, aggregate(column(rows, name)))
          }
          out
        },
      )))
    .flatten()
}

// Summaries per group, in group order, and then for the body as a whole.
#let summary-values(spec) = {
  let groups = spec.groups.map(group => _rows-for(
    spec.summaries,
    group.rows.map(position => spec.data.at(position)),
    spec.columns,
  ))
  (
    groups: groups,
    grand: _rows-for(spec.grand-summaries, spec.data, spec.columns),
  )
}
