///! Row-store normalisation, column extraction, and grouping.
///!
///! The canonical shape is a row store: an array of dictionaries, one per row.
///! A column store, a dictionary of equal-length arrays, is accepted and
///! converted. Every normalised row carries the reserved `_index` key, holding
///! its position in the input data, so predicates can read position without a
///! second parameter.

#import "utils/errors.typ": check, fail, fail-type

#let _from-columns(data) = {
  let names = data.keys()
  if names.len() == 0 { return () }
  let size = data.at(names.first()).len()
  for name in names {
    check(
      type(data.at(name)) == array,
      "data",
      "column " + name + " is not an array",
      value: data.at(name),
      hint: "A column store maps each name to an array of values.",
    )
    check(
      data.at(name).len() == size,
      "data",
      "column " + name + " has " + str(data.at(name).len()) + " values, expected " + str(size),
      hint: "Every column must have the same length.",
    )
  }
  range(size).map(index => {
    let row = (:)
    for name in names { row.insert(name, data.at(name).at(index)) }
    row
  })
}

#let normalise(data) = {
  let rows = if type(data) == dictionary { _from-columns(data) } else { data }
  if type(rows) != array {
    fail-type("data", "data", data, "an array of rows or a dictionary of columns")
  }
  rows
    .enumerate()
    .map(((index, row)) => {
      if type(row) != dictionary {
        fail-type("data", "row " + str(index), row, "a dictionary")
      }
      check(
        "_index" not in row,
        "data",
        "_index is reserved",
        hint: "Rename the column; keisen uses _index for the row position.",
      )
      row + (_index: index)
    })
}

// Names of the data columns, in first-row order, excluding the reserved key.
#let column-names(rows) = {
  if rows.len() == 0 { return () }
  rows.first().keys().filter(name => name != "_index")
}

// A column as an array, with `none` wherever a row lacks the key.
#let column(rows, name) = rows.map(row => row.at(name, default: none))

// Rows bucketed by `key(row)`, preserving input order inside each bucket.
#let group-by(rows, key) = {
  let buckets = (:)
  for row in rows {
    let label = str(key(row))
    buckets.insert(label, buckets.at(label, default: ()) + (row,))
  }
  buckets
}
