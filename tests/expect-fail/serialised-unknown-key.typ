// A typo in a top-level key used to be dropped without a word, so the table
// simply came out missing a part.
// expect: display-table: unknown key summarie in the specification
// expect: Known keys: kind, data, header, stub, row-groups, labels, hidden, combines, moves, spanners, widths, alignments, formats, substitutions, colours, summaries, grand-summaries, styles, footnotes, source-notes, options.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (kind: "display-table", data: ((units: 1),), summarie: ()),
  build-spec,
)
