///! Footnotes with marks, and source notes.

// A source note carries no mark; it explains the table as a whole.
#let table-source-note(note) = (
  kind: "source-note",
  note: note,
)

// A footnote carries a mark unless it has no location, in which case it is an
// unmarked note in the footer, like a source note with its own styling.
#let table-footnote(note, locations: none, mark: auto) = (
  kind: "footnote",
  note: note,
  locations: locations,
  mark: mark,
)

// Marks in reading order: header, then column labels and spanners, then the
// body in display order, then the footer. Identical notes share one mark, so
// repeating the same caveat does not renumber the table.
#let MARK-ORDER = (
  "title",
  "column-spanners",
  "column-labels",
  "stubhead",
  "row-groups",
  "stub",
  "body",
  "summary",
  "grand-summary",
  "source-notes",
)

#let numbering-of(style) = {
  if style == "letters" { position => numbering("a", position) }
  else if style == "symbols" { position => numbering("*", position) }
  else { position => numbering("1", position) }
}
