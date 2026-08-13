///! Stub column, row names, groups, and indentation.
///!
///! The stub is the labelling column on the leading edge: it names each row,
///! and optionally divides the body into labelled groups. Both columns leave
///! the ordinary column list, since they label the table rather than carry
///! data, but they stay in the row store for predicates to read.

// `indent` names a column of integers, one indentation level per row.
#let table-stub(rowname: none, group: none, label: none, indent: none) = (
  kind: "stub",
  rowname: rowname,
  group: group,
  label: label,
  indent: indent,
)

// The data columns a stub claims, in one place, so adding a stub key does not
// mean editing every loop that walks them.
#let stub-column-names(stub) = {
  (stub.rowname, stub.group, stub.indent).filter(name => name != none)
}

// Groups in first-appearance order, each carrying the positions of its rows.
// Order comes from the data rather than from sorting, because a table's group
// order is an editorial decision that belongs upstream.
#let build-groups(rows, name) = {
  if name == none { return () }
  let order = ()
  let members = (:)
  for (position, row) in rows.enumerate() {
    let label = str(row.at(name, default: none))
    if label not in members {
      order.push(label)
      members.insert(label, ())
    }
    members.insert(label, members.at(label) + (position,))
  }
  order.map(label => (label: label, rows: members.at(label)))
}
