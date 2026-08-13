///! Footnotes with marks, and source notes.

// A source note carries no mark; it explains the table as a whole.
#let table-source-note(note) = (
  kind: "source-note",
  note: note,
)
