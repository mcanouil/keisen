///! Alignment inside a combined cell.
///!
///! A combine pattern is a closure that returns content, so what it builds
///! cannot be read back directly. The pattern is called once more with a
///! marker in place of each source value, and the content it returns is split
///! at the markers: the markers are the values, everything between them is
///! glue. Each value then lines up down the column on its own separator, and
///! each piece of glue lines up with the glue at the same place in other rows.

#let _KEY = "keisen-value"

// A marker for the source at `index`, counted from 0 in `from` order.
#let value-marker(index) = metadata((keisen-value: index))

#let _marker-index(body) = {
  if type(body) != content or body.func() != metadata { return none }
  let value = body.value
  if type(value) != dictionary or value.keys() != (_KEY,) { return none }
  value.at(_KEY)
}

// The children of a content tree, with nested sequences expanded in place and
// empty sequences dropped. `+` flattens a sequence it joins and markup nests
// it, so two calls that build the same text can differ only in nesting; this
// is the form they are compared in.
#let flatten(body) = {
  if type(body) != content { return (body,) }
  if body.func() == [].func() {
    body.children.map(flatten).join(default: ())
  } else {
    (body,)
  }
}

// The marker an element wraps, when the marker is its only content: `strong`,
// `emph` and `highlight` hold it as `body`, and a `text(..)` call with
// settings returns a styled element that holds it as `child`.
#let _wrapped-index(element) = {
  let fields = element.fields()
  for name in ("body", "child") {
    if name in fields { return _marker-index(fields.at(name)) }
  }
  none
}

// Whether a marker sits anywhere inside an element, however deep.
#let _holds-marker(element) = {
  if _marker-index(element) != none { return true }
  if type(element) != content { return false }
  if element.func() == [].func() { return element.children.any(_holds-marker) }
  element.fields().values().any(field => (
    (type(field) == content and _holds-marker(field))
      or (type(field) == array and field.any(_holds-marker))
  ))
}

// The pieces of a pattern's output, in order: `(kind: "value", index,
// wrapper)` or `(kind: "glue", body)`. `wrapper` is the element around the
// marker, or `none` for a bare one. Returns `none` when the output cannot be
// split: a marker nested deeper than one wrapper, a source written twice or
// left out.
#let split-pattern(output, count) = {
  let pieces = ()
  let glue = ()
  let seen = ()
  for child in flatten(output) {
    let index = _marker-index(child)
    let wrapper = none
    if index == none and type(child) == content {
      index = _wrapped-index(child)
      if index != none { wrapper = child }
    }
    if index == none {
      if _holds-marker(child) { return none }
      glue.push(child)
      continue
    }
    if index in seen { return none }
    seen.push(index)
    if glue.len() > 0 { pieces.push((kind: "glue", body: glue.join())) }
    glue = ()
    pieces.push((kind: "value", index: index, wrapper: wrapper))
  }
  if glue.len() > 0 { pieces.push((kind: "glue", body: glue.join())) }
  if seen.sorted() != range(count) { return none }
  pieces
}
