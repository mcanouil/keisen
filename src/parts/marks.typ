///! Footnote marks and the order they are assigned in.
///!
///! Marks are local content, not Typst `footnote` elements, so they never
///! renumber the page footnotes a document may already have.

#import "../locations.typ": expand
#import "notes.typ": MARK-ORDER, numbering-of

#let _rank(address, spec) = {
  let part = MARK-ORDER.position(name => name == address.part)
  let part-rank = if part == none { MARK-ORDER.len() } else { part }
  let row = if type(address.row) == int { address.row } else { -1 }
  (part-rank, row)
}

// One entry per footnote: its note, its mark, and the addresses it marks.
// Notes are numbered in reading order of their first address, and two notes
// with the same content share a mark.
#let assign-marks(spec) = {
  let resolved = spec.footnotes.map(directive => {
    let addresses = if directive.locations == none { () } else {
      expand(directive.locations, spec)
    }
    let ranks = addresses.map(address => _rank(address, spec))
    (
      note: directive.note,
      mark: directive.mark,
      addresses: addresses,
      rank: if ranks.len() == 0 { (MARK-ORDER.len(), -1) } else { ranks.sorted().first() },
    )
  })

  let order = resolved.enumerate().sorted(key: ((index, entry)) => (entry.rank, index))

  let marks = (:)
  let numbered = ()
  let next = 1
  let style = numbering-of(spec.options.at("footnote-marks", default: "numbers"))

  for (index, entry) in order {
    if entry.addresses.len() == 0 {
      numbered.push((index: index, mark: none, entry: entry))
      continue
    }
    let key = repr(entry.note)
    if key not in marks {
      marks.insert(key, if entry.mark == auto { style(next) } else { entry.mark })
      if entry.mark == auto { next += 1 }
    }
    numbered.push((index: index, mark: marks.at(key), entry: entry))
  }

  numbered.sorted(key: entry => entry.index).map(entry => (
    note: entry.entry.note,
    mark: entry.mark,
    addresses: entry.entry.addresses,
  ))
}

// Marks that belong on one cell, in the order they were numbered.
#let marks-for(footnotes, part, row, column) = {
  footnotes
    .filter(footnote => footnote.mark != none)
    .filter(footnote => footnote.addresses.any(address => (
      address.part == part and address.row == row and address.column == column
    )))
    .map(footnote => footnote.mark)
}
