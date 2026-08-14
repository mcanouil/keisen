///! Footnote marks and the order they are assigned in.
///!
///! Marks are local content, not Typst `footnote` elements, so they never
///! renumber the page footnotes a document may already have.

#import "../locations.typ": expand
#import "../render/plan.typ": build-plan
#import "../theme/options.typ": option
#import "notes.typ": MARK-ORDER, numbering-of

// Where each body, stub, group, and note row actually appears, so "reading
// order" means the order a reader meets the cells rather than the order the
// data happened to arrive in. Grouping reorders rows, and marks must follow.
#let _display-order(spec) = {
  let order = (:)
  for (position, entry) in build-plan(spec).rows.enumerate() {
    if entry.source == none { continue }
    // Keyed by `repr` rather than `str`, because a summary row is identified by
    // the pair `(group, row)` and would otherwise have no place in the order.
    let parts = if entry.part == "body" { ("body", "stub") } else if entry.part == "group" {
      ("row-groups",)
    } else if entry.part == "summary" { ("summary",) } else if entry.part == "grand-summary" {
      ("grand-summary",)
    } else if entry.part == "source-note" { ("source-notes",) } else { () }
    for part in parts { order.insert(part + "|" + repr(entry.source), position) }
  }
  order
}

#let _rank(address, spec, display, columns) = {
  let part = MARK-ORDER.position(name => name == address.part)
  let part-rank = if part == none { MARK-ORDER.len() } else { part }

  // Within a part, follow the rendered row, then the column left to right.
  let row = display.at(
    address.part + "|" + repr(address.row),
    default: if type(address.row) == int { address.row } else { -1 },
  )

  let column = columns.position(name => name == address.column)
  (part-rank, row, if column == none { -1 } else { column })
}

// One entry per footnote: its note, its mark, and the addresses it marks.
// Notes are numbered in reading order of their first address, and two notes
// with the same content share a mark.
#let assign-marks(spec) = {
  let display = _display-order(spec)
  let columns = spec.columns

  let resolved = spec.footnotes.map(directive => {
    let addresses = if directive.locations == none { () } else {
      expand(directive.locations, spec)
    }
    let ranks = addresses.map(address => _rank(address, spec, display, columns))
    (
      note: directive.note,
      mark: directive.mark,
      addresses: addresses,
      rank: if ranks.len() == 0 { (MARK-ORDER.len(), -1, -1) } else { ranks.sorted().first() },
    )
  })

  let order = resolved.enumerate().sorted(key: ((index, entry)) => (entry.rank, index))

  let marks = (:)
  let numbered = ()
  let next = 1
  let style = numbering-of(option(spec.options, "footnote-marks"))

  for (position, (index, entry)) in order.enumerate() {
    if entry.addresses.len() == 0 {
      numbered.push((index: index, position: position, mark: none, entry: entry))
      continue
    }
    // Keyed by the note and the mark asked for: two notes reading the same but
    // marked differently are two marks, and the caller's choice is not lost.
    let key = repr(entry.note) + "|" + repr(entry.mark)
    if key not in marks {
      marks.insert(key, if entry.mark == auto { style(next) } else { entry.mark })
      if entry.mark == auto { next += 1 }
    }
    numbered.push((index: index, position: position, mark: marks.at(key), entry: entry))
  }

  // Returned in the order the directives were written, since that is what every
  // caller but the footer wants; `position` carries the reading order the marks
  // were numbered in, which is the order the footer prints them in.
  numbered.sorted(key: entry => entry.index).map(entry => (
    note: entry.entry.note,
    mark: entry.mark,
    position: entry.position,
    addresses: entry.entry.addresses,
  ))
}

// The footer, in the order it prints: the marked notes behind their marks, then
// the unmarked ones, which explain the table rather than a cell.
//
// Marked notes follow their marks rather than the order they were written in. A
// note marking a row further down is numbered later, so printing the footer in
// directive order would list mark 2 above mark 1, and cells-footnotes would
// address rows a reader counting marks could not predict.
// Parenthesised because a leading `+` on a new line parses as a unary operator
// on the array below it rather than as concatenation.
#let footer-notes(footnotes) = (
  footnotes.filter(footnote => footnote.mark != none).sorted(key: footnote => footnote.position)
    + footnotes.filter(footnote => footnote.mark == none)
)

// Marks that belong on one cell, in the order they were numbered.
#let marks-for(footnotes, part, row, column) = {
  footnotes
    .filter(footnote => footnote.mark != none)
    .filter(footnote => footnote.addresses.any(address => (
      address.part == part and address.row == row and address.column == column
    )))
    .map(footnote => footnote.mark)
}
