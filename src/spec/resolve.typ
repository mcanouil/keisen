///! Resolution of directives that depend on the final shape of the table.
///!
///! Most directives record what they are told and are validated once at the
///! end. Column ordering could not: `columns-move` used to resolve its anchor
///! against the column list as it stood mid-fold, so hiding the anchor, or
///! promoting it into the stub, changed whether the move succeeded depending on
///! which line was written first. That contradicts the architecture's claim
///! that directive order is free.
///!
///! Ordering now happens here, once, after every directive has been recorded,
///! so a move sees the columns the table actually has.

#import "../parts/stub.typ": stub-column-names
#import "../utils/errors.typ": check, check-column

// A column that exists but is not in the table is not an unknown column, and
// saying so would send the reader hunting for a typo that is not there.
#let _check-visible(spec, name) = {
  check(
    name not in spec.hidden,
    "columns-move",
    "column " + name + " is hidden",
    hint: "Move a visible column, or drop the columns-hide.",
  )
  check(
    name not in stub-column-names(spec.stub),
    "columns-move",
    "column " + name + " is in the stub",
    hint: "The stub sits on the leading edge; its columns are not reordered.",
  )
  check-column(spec.columns, "columns-move", name)
}

#let apply-moves(spec) = {
  let columns = spec.columns

  for directive in spec.moves {
    let anchor = if directive.before != none { directive.before } else { directive.after }
    check(
      anchor != none,
      "columns-move",
      "no anchor given",
      hint: "Pass before: or after: naming the column to move relative to.",
    )

    for name in directive.columns { _check-visible(spec, name) }
    _check-visible(spec, anchor)
    check(
      anchor not in directive.columns,
      "columns-move",
      "cannot move " + anchor + " relative to itself",
      hint: "Move relative to a column other than the ones being moved.",
    )

    let rest = columns.filter(name => name not in directive.columns)
    let at = rest.position(name => name == anchor)
    let cut = if directive.before != none { at } else { at + 1 }
    columns = rest.slice(0, cut) + directive.columns + rest.slice(cut)
  }

  spec.columns = columns
  spec
}
