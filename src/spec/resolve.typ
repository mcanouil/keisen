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

#import "../utils/errors.typ": check, check-column

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

    for name in directive.columns { check-column(columns, "columns-move", name) }
    check-column(columns, "columns-move", anchor)
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
